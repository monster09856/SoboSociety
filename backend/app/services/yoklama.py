from dataclasses import dataclass
from datetime import datetime

from sqlalchemy import update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import (
    Booking, BookingDurumu, ClassSession, ClassType, LedgerTipi,
)
from app.services.kredi import hareket_ekle


@dataclass(frozen=True)
class YoklamaSonucu:
    gelen: int
    gelmeyen: int


async def yoklama_al(
    db: AsyncSession,
    *,
    session_id: int,
    gelen_member_ids: set[int],
    now: datetime,
) -> YoklamaSonucu:
    """Dersin yoklamasını tek işlemde alır.

    Eğitmen panelde listeye bakıp gelenleri işaretler ve bir kez kaydeder.
    Üye üye çağrı yapmak yarım kalmış yoklama üretir — beşinci kişide
    bağlantı koparsa ders yarı işlenmiş kalır.

    İdempotenttir: yalnız hâlâ BOOKED durumdaki kayıtlar işlenir. Eğitmen
    kaydet'e iki kez basarsa ikinci çağrı hiçbir şey yapmaz ve no-show
    cezası iki kez yazılmaz. Bu idempotanlık ORM ataması yerine ATOMİK
    toplu UPDATE ile sağlanır: `durum = 'booked'` koşulu veritabanı
    seviyesinde uygulanır, uygulama kodundaki bir filtreden değil. Eğitmen
    "kaydet"e çift tıklayıp iki eşzamanlı çağrı aynı anda gelirse, ikinci
    UPDATE hiçbir satır etkilemez ve ceza iki kez yazılmaz.

    No-show KONTENJANI GERİ VERMEZ: ders geçmiştir, o yerin başkasına
    satılması diye bir şey yok. Geçmiş dersin kaç kişiyle yapıldığı bilgisi
    de korunmalı.
    """
    oturum = await db.get(ClassSession, session_id)
    if oturum is None:
        raise ValueError(f"Ders bulunamadı: {session_id}")
    tip = await db.get(ClassType, oturum.class_type_id)

    # Gelenleri işaretle. ORM ataması yerine atomik UPDATE: idempotanlık
    # `durum = 'booked'` koşulundan gelir, uygulama kodundaki filtreden
    # değil. Eğitmen "kaydet"e çift tıklarsa ikinci çağrı hiçbir satır
    # etkilemez ve ceza iki kez yazılmaz.
    gelen_ids = list(gelen_member_ids)
    gelen_sayisi = 0
    if gelen_ids:
        sonuc = await db.execute(
            update(Booking)
            .where(
                Booking.session_id == session_id,
                Booking.durum == BookingDurumu.BOOKED,
                Booking.member_id.in_(gelen_ids),
            )
            .values(durum=BookingDurumu.ATTENDED)
            .returning(Booking.id)
        )
        gelen_sayisi = len(sonuc.scalars().all())

    # Gelmeyenleri işaretle ve ceza satırlarını yaz. RETURNING ile hangi
    # kayıtların GERÇEKTEN bu çağrıda kapatıldığını öğreniyoruz; ledger
    # satırları yalnız onlar için yazılır.
    gelmeyen_kosullar = [
        Booking.session_id == session_id,
        Booking.durum == BookingDurumu.BOOKED,
    ]
    if gelen_ids:
        gelmeyen_kosullar.append(Booking.member_id.notin_(gelen_ids))

    sonuc = await db.execute(
        update(Booking)
        .where(*gelmeyen_kosullar)
        .values(durum=BookingDurumu.NO_SHOW)
        .returning(Booking.id, Booking.member_id)
    )
    gelmeyenler = sonuc.all()

    for booking_id, member_id in gelmeyenler:
        await hareket_ekle(
            db,
            member_id=member_id,
            tip=LedgerTipi.NO_SHOW,
            miktar=0,
            sebep=f"{tip.ad} — {oturum.baslangic:%d.%m.%Y %H:%M} UTC dersine gelinmedi",
            booking_id=booking_id,
        )

    await db.flush()
    return YoklamaSonucu(gelen=gelen_sayisi, gelmeyen=len(gelmeyenler))
