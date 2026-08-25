from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import (
    Booking, BookingDurumu, BookingKaynagi, ClassSession,
    ClassType, LedgerTipi, SessionDurumu,
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
    """
    oturum = await db.get(ClassSession, session_id)
    if oturum is None:
        raise ValueError(f"Ders bulunamadı: {session_id}")
    if oturum.durum != SessionDurumu.AKTIF:
        raise DersIptalEdilmis("Bu ders iptal edilmiş")

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
    db.add(kayit)
    await db.flush()

    tip = await db.get(ClassType, oturum.class_type_id)
    await hareket_ekle(
        db,
        member_id=member_id,
        tip=LedgerTipi.BOOKING,
        miktar=-1,
        sebep=f"{tip.ad} — {oturum.baslangic:%d.%m.%Y %H:%M} UTC",
        booking_id=kayit.id,
    )
    return kayit
