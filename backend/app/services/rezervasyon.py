from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import (
    Booking, BookingDurumu, BookingKaynagi, ClassSession,
    ClassType, LedgerTipi, Member, SessionDurumu,
)
from app.services.hatalar import (
    DersDolu, DersIptalEdilmis, YetersizKredi, ZatenRezerve,
)
from app.services.kredi import bakiye, hareket_ekle


async def rezerve_et(
    db: AsyncSession,
    *,
    member_id: int,
    session_id: int,
    kaynak: BookingKaynagi = BookingKaynagi.APP,
) -> Booking:
    """Üyeyi derse kaydeder, kredisinden bir ders düşer.

    Sıra önemlidir: önce ucuz ve reddedici kontroller (iptal, çift kayıt,
    kredi), en son kontenjan artışı. Reddedilecek bir istek kontenjandan
    geçici olarak yer çalmamalı.

    Atomiklik tamamen çağıranın transaction disiplinine bağlıdır: bu
    fonksiyon commit yapmaz (repo genelinde tutarlı bir desen). Çağıran
    tek bir transaction içinde çağırmalı ve bir hata (ör. `DersDolu`,
    `YetersizKredi`) fırlarsa transaction'ı rollback etmelidir.
    """
    oturum = await db.get(ClassSession, session_id)
    if oturum is None:
        raise ValueError(f"Ders bulunamadı: {session_id}")
    if oturum.durum != SessionDurumu.AKTIF:
        raise DersIptalEdilmis("Bu ders iptal edilmiş")

    tip = await db.get(ClassType, oturum.class_type_id)
    if tip is None:
        raise ValueError(f"Ders tipi bulunamadı: {oturum.class_type_id}")

    # Bu üyenin eşzamanlı rezervasyon isteklerini serileştir.
    #
    # İki yarışı birden kapatır: (1) bakiye okuması ile ledger yazması
    # arasındaki pencere — 1 kredisi kalan üye iki farklı derse aynı anda
    # basıp ikisini birden alabiliyordu; (2) aynı derse iki sekmeden
    # basıldığında kısmi unique index'in ham IntegrityError üretmesi.
    # Kilit kapsamı tek üye satırı olduğu için çekişme pratikte yok:
    # bir üye aynı anda çoklu rezervasyon yapmaz.
    kilit = await db.execute(
        select(Member.id).where(Member.id == member_id).with_for_update()
    )
    if kilit.scalar_one_or_none() is None:
        raise ValueError(f"Üye bulunamadı: {member_id}")

    mevcut = await db.execute(
        select(Booking).where(
            Booking.member_id == member_id,
            Booking.session_id == session_id,
            Booking.durum == BookingDurumu.BOOKED,
        )
    )
    if mevcut.scalar_one_or_none() is not None:
        raise ZatenRezerve("Bu derse zaten kayıtlısın")

    if await bakiye(db, member_id) < 1:
        raise YetersizKredi("Ders paketinde yeterli hak yok")

    # Kontenjanı atomik olarak artır. Etkilenen satır 0 ise ders dolmuştur.
    # SELECT FOR UPDATE değil: bu tek round-trip ve deadlock üretmiyor.
    # "Önce say sonra ekle" ise çalışmaz — iki istek aynı sayıyı okur.
    sonuc = await db.execute(
        update(ClassSession)
        .where(
            ClassSession.id == session_id,
            ClassSession.dolu_sayi < ClassSession.kontenjan,
            ClassSession.durum == SessionDurumu.AKTIF,
        )
        .values(dolu_sayi=ClassSession.dolu_sayi + 1)
        .returning(ClassSession.dolu_sayi)
    )
    if sonuc.first() is None:
        raise DersDolu("Ders dolu")

    kayit = Booking(
        member_id=member_id,
        session_id=session_id,
        durum=BookingDurumu.BOOKED,
        kaynak=kaynak,
    )
    # İkincil savunma: üye kilidi çift kaydı zaten önlüyor, ama kısmi
    # unique index son savunma hattı olarak kalsın. SAVEPOINT olmadan
    # IntegrityError tüm transaction'ı zehirler ve çağıran rollback etmek
    # zorunda kalır — burada yakalayıp domain hatasına çeviriyoruz.
    try:
        async with db.begin_nested():
            db.add(kayit)
            await db.flush()
    except IntegrityError as hata:
        raise ZatenRezerve("Bu derse zaten kayıtlısın") from hata

    await hareket_ekle(
        db,
        member_id=member_id,
        tip=LedgerTipi.BOOKING,
        miktar=-1,
        sebep=f"{tip.ad} — {oturum.baslangic:%d.%m.%Y %H:%M} UTC",
        booking_id=kayit.id,
    )
    return kayit
