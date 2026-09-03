import asyncio
from datetime import datetime, UTC, timedelta, date

from sqlalchemy import select
from app.db.session import OturumFabrikasi, motor
from app.models import Base
from app.models.program import ClassType, Room, ScheduleTemplate, ClassSession, SessionDurumu
from app.models.uyelik import Member, Instructor
from app.models.kredi import Package
from app.services.kredi import paket_tanimla
from app.services.program_uretimi import uret

async def seed():
    print("Veritabanı tabloları kontrol ediliyor...")
    async with motor.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with OturumFabrikasi() as session:
        print("Tohum verileri kontrol ediliyor...")
        
        # 1. Salon
        res = await session.execute(select(Room).where(Room.ad == "Main Studio"))
        room = res.scalar_one_or_none()
        if not room:
            room = Room(ad="Main Studio", aktif=True)
            session.add(room)
            await session.flush()

        # 2. Eğitmenler
        res = await session.execute(select(Instructor).where(Instructor.ad == "Pelin Hoca"))
        pelin = res.scalar_one_or_none()
        if not pelin:
            pelin = Instructor(ad="Pelin Hoca", biyografi="Barre ve Pilates Eğitmeni", aktif=True)
            session.add(pelin)
            await session.flush()

        res = await session.execute(select(Instructor).where(Instructor.ad == "Zeynep Hoca"))
        zeynep = res.scalar_one_or_none()
        if not zeynep:
            zeynep = Instructor(ad="Zeynep Hoca", biyografi="Functional & Movement Eğitmeni", aktif=True)
            session.add(zeynep)
            await session.flush()

        # 3. Ders Tipleri
        barre = (await session.execute(select(ClassType).where(ClassType.ad == "Barre"))).scalar_one_or_none()
        if not barre:
            barre = ClassType(ad="Barre", kontenjan=5, sure_dk=50, renk="#A2846F", iptal_penceresi_saat=6)
            session.add(barre)

        pilates = (await session.execute(select(ClassType).where(ClassType.ad == "Pilates"))).scalar_one_or_none()
        if not pilates:
            pilates = ClassType(ad="Pilates", kontenjan=5, sure_dk=50, renk="#6F5647", iptal_penceresi_saat=6)
            session.add(pilates)

        functional = (await session.execute(select(ClassType).where(ClassType.ad == "Functional"))).scalar_one_or_none()
        if not functional:
            functional = ClassType(ad="Functional", kontenjan=5, sure_dk=50, renk="#7D8B72", iptal_penceresi_saat=6)
            session.add(functional)

        await session.flush()

        # 4. Paketler (Gerçek Stüdyo Paketleri)
        real_packages = [
            {"ad": "Barre Class Tek Ders", "ders_adedi": 1, "gecerlilik_gun": 7, "fiyat_kurus": 90000},
            {"ad": "Barre Class 4 Ders", "ders_adedi": 4, "gecerlilik_gun": 28, "fiyat_kurus": 350000},
            {"ad": "Sobo Class (8 Ders / 6 Hafta)", "ders_adedi": 8, "gecerlilik_gun": 42, "fiyat_kurus": 640000},
            {"ad": "Sobo Class (12 Ders / 8 Hafta)", "ders_adedi": 12, "gecerlilik_gun": 56, "fiyat_kurus": 840000},
            {"ad": "Yoga Class Tek Ders", "ders_adedi": 1, "gecerlilik_gun": 7, "fiyat_kurus": 85000},
            {"ad": "Yoga Class 4 Ders", "ders_adedi": 4, "gecerlilik_gun": 35, "fiyat_kurus": 300000},
            {"ad": "Barre Class Bireysel", "ders_adedi": 8, "gecerlilik_gun": 42, "fiyat_kurus": 880000},
            {"ad": "Barre Class Bireysel Premium", "ders_adedi": 12, "gecerlilik_gun": 56, "fiyat_kurus": 1180000},
            {"ad": "Reformer Class Bireysel", "ders_adedi": 8, "gecerlilik_gun": 42, "fiyat_kurus": 750000},
            {"ad": "Reformer Class Bireysel Elite", "ders_adedi": 12, "gecerlilik_gun": 56, "fiyat_kurus": 950000},
        ]
        for p in real_packages:
            ex = (await session.execute(select(Package).where(Package.ad == p["ad"]))).scalar_one_or_none()
            if not ex:
                session.add(Package(**p, aktif=True))
        await session.flush()

        # 5. Üyeler (Admin & Örnek Üye)
        admin = (await session.execute(select(Member).where(Member.telefon == "+905555555555"))).scalar_one_or_none()
        if not admin:
            admin = Member(telefon="+905555555555", ad="Admin Pelin")
            session.add(admin)

        uye = (await session.execute(select(Member).where(Member.telefon == "+905551234567"))).scalar_one_or_none()
        if not uye:
            uye = Member(telefon="+905551234567", ad="Ayşe Yılmaz")
            session.add(uye)

        await session.flush()

        # Üyeye paket tanımla
        await paket_tanimla(session, member_id=uye.id, package_id=p_starter.id, baslangic=date.today())

        # 6. Haftalık Şablonlar
        templates_count = (await session.execute(select(ScheduleTemplate))).scalars().all()
        if not templates_count:
            today_date = date.today()
            templates = [
                ScheduleTemplate(hafta_gunu=0, saat_dk=600, class_type_id=barre.id, instructor_id=pelin.id, room_id=room.id, gecerli_baslangic=today_date),
                ScheduleTemplate(hafta_gunu=0, saat_dk=1140, class_type_id=pilates.id, instructor_id=pelin.id, room_id=room.id, gecerli_baslangic=today_date),
                ScheduleTemplate(hafta_gunu=1, saat_dk=600, class_type_id=pilates.id, instructor_id=pelin.id, room_id=room.id, gecerli_baslangic=today_date),
                ScheduleTemplate(hafta_gunu=1, saat_dk=1140, class_type_id=functional.id, instructor_id=zeynep.id, room_id=room.id, gecerli_baslangic=today_date),
                ScheduleTemplate(hafta_gunu=2, saat_dk=600, class_type_id=functional.id, instructor_id=zeynep.id, room_id=room.id, gecerli_baslangic=today_date),
                ScheduleTemplate(hafta_gunu=2, saat_dk=1140, class_type_id=barre.id, instructor_id=pelin.id, room_id=room.id, gecerli_baslangic=today_date),
                ScheduleTemplate(hafta_gunu=3, saat_dk=600, class_type_id=barre.id, instructor_id=pelin.id, room_id=room.id, gecerli_baslangic=today_date),
                ScheduleTemplate(hafta_gunu=3, saat_dk=1140, class_type_id=pilates.id, instructor_id=pelin.id, room_id=room.id, gecerli_baslangic=today_date),
                ScheduleTemplate(hafta_gunu=4, saat_dk=600, class_type_id=pilates.id, instructor_id=pelin.id, room_id=room.id, gecerli_baslangic=today_date),
                ScheduleTemplate(hafta_gunu=4, saat_dk=1140, class_type_id=functional.id, instructor_id=zeynep.id, room_id=room.id, gecerli_baslangic=today_date),
                ScheduleTemplate(hafta_gunu=5, saat_dk=660, class_type_id=functional.id, instructor_id=zeynep.id, room_id=room.id, gecerli_baslangic=today_date),
                ScheduleTemplate(hafta_gunu=6, saat_dk=660, class_type_id=barre.id, instructor_id=pelin.id, room_id=room.id, gecerli_baslangic=today_date),
            ]
            session.add_all(templates)
            await session.flush()

        # 7. Oturumları Üret (bugünden itibaren 14 gün)
        baslangic_tarih = date.today()
        bitis_tarih = baslangic_tarih + timedelta(days=14)
        await uret(session, baslangic=baslangic_tarih, bitis=bitis_tarih)

        await session.commit()
        print("Demo verileri başarıyla yüklendi!")

if __name__ == "__main__":
    asyncio.run(seed())
