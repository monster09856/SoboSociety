# app/services/program_uretimi.py
from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import ClassSession, ClassType, ScheduleTemplate

STUDYO_TZ = ZoneInfo("Europe/Istanbul")


def _yerel_ani_utc_ye_cevir(gun: date, saat_dk: int) -> datetime:
    """Şablondaki yerel saati o güne uygulayıp UTC'ye çevirir.

    Şablon "her Salı 19:00" der ve bu YEREL bir saattir. UTC saklamak yanlış
    olurdu: ülke saat dilimi kuralını değiştirirse (Türkiye 2016'da yaptı)
    tüm şablonlar sessizce kayardı.
    """
    yerel = datetime.combine(gun, time(hour=saat_dk // 60, minute=saat_dk % 60))
    return yerel.replace(tzinfo=STUDYO_TZ).astimezone(ZoneInfo("UTC"))


async def uret(db: AsyncSession, *, baslangic: date, bitis: date) -> int:
    """`baslangic` ve `bitis` (dahil) arasındaki günler için oturum üretir.

    İdempotenttir: aynı aralık için iki kez çağrılırsa ikincisi 0 döner.
    Garanti veritabanından gelir (`uq_salon_saat` + ON CONFLICT DO NOTHING),
    uygulama kodundaki "önce var mı" kontrolünden değil — o kontrol yarış
    koşuluna açıktır.
    """
    sonuc = await db.execute(
        select(ScheduleTemplate, ClassType.kontenjan)
        .join(ClassType, ClassType.id == ScheduleTemplate.class_type_id)
        .where(ClassType.aktif.is_(True))
    )
    sablonlar = sonuc.all()
    if not sablonlar:
        return 0

    satirlar: list[dict] = []
    gun = baslangic
    while gun <= bitis:
        for sablon, kontenjan in sablonlar:
            if sablon.hafta_gunu != gun.weekday():
                continue
            if gun < sablon.gecerli_baslangic:
                continue
            if sablon.gecerli_bitis is not None and gun > sablon.gecerli_bitis:
                continue

            satirlar.append({
                "baslangic": _yerel_ani_utc_ye_cevir(gun, sablon.saat_dk),
                "class_type_id": sablon.class_type_id,
                "instructor_id": sablon.instructor_id,
                "room_id": sablon.room_id,
                "kontenjan": kontenjan,
                "dolu_sayi": 0,
                "template_id": sablon.id,
            })
        gun += timedelta(days=1)

    if not satirlar:
        return 0

    stmt = (
        insert(ClassSession)
        .values(satirlar)
        .on_conflict_do_nothing(constraint="uq_salon_saat")
        .returning(ClassSession.id)
    )
    eklenen = await db.execute(stmt)
    await db.flush()
    return len(eklenen.scalars().all())
