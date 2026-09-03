from datetime import UTC, date, datetime, timedelta

import pytest
from httpx import ASGITransport, AsyncClient

from app.api.deps import get_db
from app.core.security import create_access_token
from app.main import app
from app.models import (
    Booking,
    BookingDurumu,
    BookingKaynagi,
    ClassSession,
    ClassType,
    CreditLedger,
    Instructor,
    Member,
    Package,
    Room,
    ScheduleTemplate,
)
from app.services.kredi import bakiye, paket_tanimla
from app.services.rezervasyon import rezerve_et
from app.settings import ayarlar


@pytest.fixture
async def client(db):
    async def override_get_db():
        yield db

    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac
    app.dependency_overrides.clear()


@pytest.fixture
async def admin_fixtures(db):
    admin_tel = ayarlar.admin_telefons[0]
    admin_uye = Member(telefon=admin_tel, ad="Admin Hoca", aktif=True)
    normal_uye = Member(telefon="+905321112233", ad="Normal Üye", aktif=True)

    tip = ClassType(ad="Barre Fit", kontenjan=5, sure_dk=50)
    egitmen = Instructor(ad="Eğitmen Zeynep", aktif=True)
    salon = Room(ad="Stüdyo A", aktif=True)
    paket = Package(ad="10 Derslik Paket", ders_adedi=10, gecerlilik_gun=30, fiyat_kurus=600000)

    db.add_all([admin_uye, normal_uye, tip, egitmen, salon, paket])
    await db.flush()

    # Normal üyeye paket tanımla
    await paket_tanimla(db, member_id=normal_uye.id, package_id=paket.id, baslangic=date.today())

    admin_token = create_access_token(subject=str(admin_uye.id), is_admin=True)
    normal_token = create_access_token(subject=str(normal_uye.id), is_admin=False)

    admin_headers = {"Authorization": f"Bearer {admin_token}"}
    normal_headers = {"Authorization": f"Bearer {normal_token}"}

    return {
        "admin_uye": admin_uye,
        "normal_uye": normal_uye,
        "admin_headers": admin_headers,
        "normal_headers": normal_headers,
        "tip": tip,
        "egitmen": egitmen,
        "salon": salon,
        "paket": paket,
    }


async def test_admin_endpoints_unauthorized_ve_forbidden(client: AsyncClient, admin_fixtures):
    # Token olmadan çağrı -> 401
    res1 = await client.get("/api/v1/admin/today")
    assert res1.status_code == 401

    # Normal üye (admin olmayan) -> 403
    normal_headers = admin_fixtures["normal_headers"]
    res2 = await client.get("/api/v1/admin/today", headers=normal_headers)
    assert res2.status_code == 403

    res3 = await client.post(
        "/api/v1/admin/quick-booking",
        json={"telefon": "+905359998877", "session_id": 1},
        headers=normal_headers,
    )
    assert res3.status_code == 403

    res4 = await client.post(
        "/api/v1/admin/attendance",
        json={"session_id": 1, "gelen_member_ids": []},
        headers=normal_headers,
    )
    assert res4.status_code == 403

    res5 = await client.post(
        "/api/v1/admin/packages/assign",
        json={"member_id": admin_fixtures["normal_uye"].id, "package_id": admin_fixtures["paket"].id},
        headers=normal_headers,
    )
    assert res5.status_code == 403

    res6 = await client.post(
        "/api/v1/admin/sessions/generate",
        json={"baslangic": str(date.today()), "bitis": str(date.today())},
        headers=normal_headers,
    )
    assert res6.status_code == 403


async def test_get_today_sessions_endpoint(client: AsyncClient, admin_fixtures, db):
    headers = admin_fixtures["admin_headers"]
    normal_uye = admin_fixtures["normal_uye"]
    tip = admin_fixtures["tip"]
    egitmen = admin_fixtures["egitmen"]
    salon = admin_fixtures["salon"]

    # Bugünkü ders oturumu oluştur
    bugun_tarih = datetime.now(UTC) + timedelta(hours=2)
    oturum = ClassSession(
        baslangic=bugun_tarih,
        class_type_id=tip.id,
        instructor_id=egitmen.id,
        room_id=salon.id,
        kontenjan=5,
    )
    db.add(oturum)
    await db.flush()

    # Üye derse kaydolsun
    booking = await rezerve_et(db, member_id=normal_uye.id, session_id=oturum.id, now=datetime.now(UTC))
    await db.flush()

    response = await client.get("/api/v1/admin/today", headers=headers)
    assert response.status_code == 200

    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1

    # Eklenen ders listelenmeli
    session_data = next((s for s in data if s["id"] == oturum.id), None)
    assert session_data is not None
    assert session_data["kontenjan"] == 5
    assert session_data["dolu_sayi"] == 1
    assert len(session_data["katilimcilar"]) == 1

    attendee = session_data["katilimcilar"][0]
    assert attendee["booking_id"] == booking.id
    assert attendee["member_id"] == normal_uye.id
    assert attendee["ad"] == "Normal Üye"
    assert attendee["telefon"] == "+905321112233"
    assert attendee["durum"] == BookingDurumu.BOOKED


async def test_quick_booking_yeni_uye_ve_rezervasyon(client: AsyncClient, admin_fixtures, db):
    headers = admin_fixtures["admin_headers"]
    tip = admin_fixtures["tip"]
    egitmen = admin_fixtures["egitmen"]
    salon = admin_fixtures["salon"]
    paket = admin_fixtures["paket"]

    oturum = ClassSession(
        baslangic=datetime.now(UTC) + timedelta(days=1),
        class_type_id=tip.id,
        instructor_id=egitmen.id,
        room_id=salon.id,
        kontenjan=5,
    )
    db.add(oturum)
    await db.flush()

    # DM'den ilk defa yazan üye için hızlı rezervasyon (otomatik kayıt + paket tanımlama)
    yeni_tel = "0533 999 88 77"
    payload = {
        "telefon": yeni_tel,
        "ad": "DM Müşterisi Selin",
        "session_id": oturum.id,
        "package_id": paket.id,
    }

    response = await client.post("/api/v1/admin/quick-booking", json=payload, headers=headers)
    assert response.status_code == 200
    data = response.json()

    assert data["session_id"] == oturum.id
    assert data["durum"] == BookingDurumu.BOOKED
    assert data["kaynak"] == BookingKaynagi.ADMIN

    # Veritabanında yeni üye oluştu mu?
    stmt = Member.__table__.select().where(Member.telefon == "+905339998877")
    res = await db.execute(stmt)
    yeni_uye = res.fetchone()
    assert yeni_uye is not None
    assert yeni_uye.ad == "DM Müşterisi Selin"


async def test_quick_booking_mevcut_uye(client: AsyncClient, admin_fixtures, db):
    headers = admin_fixtures["admin_headers"]
    normal_uye = admin_fixtures["normal_uye"]
    tip = admin_fixtures["tip"]
    egitmen = admin_fixtures["egitmen"]
    salon = admin_fixtures["salon"]

    oturum = ClassSession(
        baslangic=datetime.now(UTC) + timedelta(days=2),
        class_type_id=tip.id,
        instructor_id=egitmen.id,
        room_id=salon.id,
        kontenjan=5,
    )
    db.add(oturum)
    await db.flush()

    payload = {
        "telefon": normal_uye.telefon,
        "session_id": oturum.id,
    }

    response = await client.post("/api/v1/admin/quick-booking", json=payload, headers=headers)
    assert response.status_code == 200
    data = response.json()

    assert data["member_id"] == normal_uye.id
    assert data["session_id"] == oturum.id
    assert data["kaynak"] == BookingKaynagi.ADMIN


async def test_package_assign_endpoint(client: AsyncClient, admin_fixtures, db):
    headers = admin_fixtures["admin_headers"]
    normal_uye = admin_fixtures["normal_uye"]
    paket = admin_fixtures["paket"]

    bakiye_once = await bakiye(db, normal_uye.id)

    payload = {
        "member_id": normal_uye.id,
        "package_id": paket.id,
        "baslangic": str(date.today()),
    }

    response = await client.post("/api/v1/admin/packages/assign", json=payload, headers=headers)
    assert response.status_code == 200
    data = response.json()

    assert data["member_id"] == normal_uye.id
    assert data["package_id"] == paket.id

    # Üyenin bakiyesi paket adedi kadar artmalı (10 artmalı)
    bakiye_sonra = await bakiye(db, normal_uye.id)
    assert bakiye_sonra == bakiye_once + paket.ders_adedi


async def test_attendance_endpoint(client: AsyncClient, admin_fixtures, db):
    headers = admin_fixtures["admin_headers"]
    normal_uye = admin_fixtures["normal_uye"]
    tip = admin_fixtures["tip"]
    egitmen = admin_fixtures["egitmen"]
    salon = admin_fixtures["salon"]

    # İkinci bir üye ekle
    ikinci_uye = Member(telefon="+905348887766", ad="İkinci Üye", aktif=True)
    db.add(ikinci_uye)
    await db.flush()
    await paket_tanimla(db, member_id=ikinci_uye.id, package_id=admin_fixtures["paket"].id, baslangic=date.today())

    # Başlangıcı geçmişte kalan bir oturum oluştur (yoklama geçmiş ders için alınır)
    gecmis_tarih = datetime.now(UTC) - timedelta(hours=1)
    oturum = ClassSession(
        baslangic=gecmis_tarih,
        class_type_id=tip.id,
        instructor_id=egitmen.id,
        room_id=salon.id,
        kontenjan=5,
    )
    db.add(oturum)
    await db.flush()

    # İki üye de derse kayıtlı olsun
    b1 = Booking(member_id=normal_uye.id, session_id=oturum.id, durum=BookingDurumu.BOOKED)
    b2 = Booking(member_id=ikinci_uye.id, session_id=oturum.id, durum=BookingDurumu.BOOKED)
    db.add_all([b1, b2])
    await db.flush()

    # Ledger satırlarını simüle et (yoklama no_show durumunda kaynak arar)
    l1 = CreditLedger(member_id=normal_uye.id, tip="booking", miktar=-1, sebep="test", booking_id=b1.id)
    l2 = CreditLedger(member_id=ikinci_uye.id, tip="booking", miktar=-1, sebep="test", booking_id=b2.id)
    db.add_all([l1, l2])
    await db.flush()

    # Yoklama al: normal_uye katıldı, ikinci_uye gelmedi
    payload = {
        "session_id": oturum.id,
        "gelen_member_ids": [normal_uye.id],
    }

    response = await client.post("/api/v1/admin/attendance", json=payload, headers=headers)
    assert response.status_code == 200
    data = response.json()

    assert data["gelen"] == 1
    assert data["gelmeyen"] == 1

    await db.refresh(b1)
    await db.refresh(b2)
    assert b1.durum == BookingDurumu.ATTENDED
    assert b2.durum == BookingDurumu.NO_SHOW


async def test_session_generate_endpoint(client: AsyncClient, admin_fixtures, db):
    headers = admin_fixtures["admin_headers"]
    tip = admin_fixtures["tip"]
    egitmen = admin_fixtures["egitmen"]
    salon = admin_fixtures["salon"]

    bugun = date.today()
    gun_indeks = bugun.weekday()

    # Şablon oluştur
    sablon = ScheduleTemplate(
        hafta_gunu=gun_indeks,
        saat_dk=600,  # 10:00
        class_type_id=tip.id,
        instructor_id=egitmen.id,
        room_id=salon.id,
        gecerli_baslangic=bugun - timedelta(days=1),
    )
    db.add(sablon)
    await db.flush()

    payload = {
        "baslangic": str(bugun),
        "bitis": str(bugun),
    }

    response = await client.post("/api/v1/admin/sessions/generate", json=payload, headers=headers)
    assert response.status_code == 200
    data = response.json()

    assert data["uretilen_oturum_sayisi"] == 1


async def test_delete_member_endpoint(client: AsyncClient, admin_fixtures, db):
    headers = admin_fixtures["admin_headers"]
    
    # Silinecek üye oluştur
    del_member = Member(ad="Silinecek Üye", telefon="+905559998877", aktif=True)
    db.add(del_member)
    await db.commit()
    await db.refresh(del_member)

    res = await client.delete(f"/api/v1/admin/members/{del_member.id}", headers=headers)
    assert res.status_code == 200
    assert "silindi" in res.json()["mesaj"]

    # Silinen üyeyi kontrol et
    check = await db.get(Member, del_member.id)
    assert check is None
