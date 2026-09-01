from datetime import UTC, date, datetime, timedelta

import pytest
from httpx import ASGITransport, AsyncClient

from app.api.deps import get_db
from app.core.security import create_access_token
from app.main import app
from app.models import (
    Booking, BookingDurumu, ClassSession, ClassType, Instructor, Member,
    Package, Room, SessionDurumu,
)
from app.services.kredi import paket_tanimla
from app.services.rezervasyon import rezerve_et


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
async def sample_data(db):
    uye = Member(telefon="+905316033080", ad="Ayşe Yılmaz")
    tip = ClassType(ad="Reformer Pilates", kontenjan=2, sure_dk=50)
    egitmen = Instructor(ad="Deniz Hoca")
    salon = Room(ad="Ana Salon")
    paket = Package(ad="8 Derslik Paket", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)

    db.add_all([uye, tip, egitmen, salon, paket])
    await db.flush()

    await paket_tanimla(
        db, member_id=uye.id, package_id=paket.id, baslangic=date.today()
    )

    gelecek_tarih = datetime.now(UTC) + timedelta(days=1)
    gecmis_tarih = datetime.now(UTC) - timedelta(days=1)

    oturum_gelecek = ClassSession(
        baslangic=gelecek_tarih,
        class_type_id=tip.id,
        instructor_id=egitmen.id,
        room_id=salon.id,
        kontenjan=2,
    )
    oturum_gecmis = ClassSession(
        baslangic=gecmis_tarih,
        class_type_id=tip.id,
        instructor_id=egitmen.id,
        room_id=salon.id,
        kontenjan=2,
    )
    oturum_iptal = ClassSession(
        baslangic=gelecek_tarih + timedelta(hours=2),
        class_type_id=tip.id,
        instructor_id=egitmen.id,
        room_id=salon.id,
        kontenjan=2,
        durum=SessionDurumu.IPTAL,
    )
    db.add_all([oturum_gelecek, oturum_gecmis, oturum_iptal])
    await db.flush()

    token = create_access_token(subject=str(uye.id))
    headers = {"Authorization": f"Bearer {token}"}

    return {
        "uye": uye,
        "token": token,
        "headers": headers,
        "oturum_gelecek": oturum_gelecek,
        "oturum_gecmis": oturum_gecmis,
        "oturum_iptal": oturum_iptal,
        "tip": tip,
        "egitmen": egitmen,
    }


async def test_list_sessions_endpoint(client: AsyncClient, sample_data):
    headers = sample_data["headers"]
    response = await client.get("/api/v1/sessions", headers=headers)
    assert response.status_code == 200

    data = response.json()
    assert isinstance(data, list)
    # Sadece gelecek ve aktif ders gelmeli
    assert len(data) == 1
    assert data[0]["id"] == sample_data["oturum_gelecek"].id
    assert data[0]["class_type"]["ad"] == "Reformer Pilates"
    assert data[0]["instructor"]["ad"] == "Deniz Hoca"


async def test_rezerve_et_endpoint_basarili(client: AsyncClient, sample_data):
    headers = sample_data["headers"]
    oturum_id = sample_data["oturum_gelecek"].id

    response = await client.post(
        "/api/v1/bookings",
        json={"session_id": oturum_id},
        headers=headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert data["session_id"] == oturum_id
    assert data["durum"] == BookingDurumu.BOOKED


async def test_rezerve_et_yetersiz_kredi_hata_verir(client: AsyncClient, db):
    # Kredisi olmayan yeni üye
    fakir_uye = Member(telefon="+905329990011", ad="Kredisiz Üye")
    tip = ClassType(ad="Yoga", kontenjan=5, sure_dk=50)
    egitmen = Instructor(ad="Ali Hoca")
    salon = Room(ad="Küçük Salon")
    db.add_all([fakir_uye, tip, egitmen, salon])
    await db.flush()

    oturum = ClassSession(
        baslangic=datetime.now(UTC) + timedelta(days=2),
        class_type_id=tip.id,
        instructor_id=egitmen.id,
        room_id=salon.id,
        kontenjan=5,
    )
    db.add(oturum)
    await db.flush()

    token = create_access_token(subject=str(fakir_uye.id))
    headers = {"Authorization": f"Bearer {token}"}

    response = await client.post(
        "/api/v1/bookings",
        json={"session_id": oturum.id},
        headers=headers,
    )
    assert response.status_code == 400
    data = response.json()
    assert data["hata"] == "YetersizKredi"


async def test_iptal_et_endpoint_basarili(client: AsyncClient, sample_data, db):
    headers = sample_data["headers"]
    uye = sample_data["uye"]
    oturum = sample_data["oturum_gelecek"]

    # Önce bir rezervasyon oluştur
    booking = await rezerve_et(
        db,
        member_id=uye.id,
        session_id=oturum.id,
        now=datetime.now(UTC),
    )
    await db.flush()

    response = await client.post(
        f"/api/v1/bookings/{booking.id}/cancel",
        headers=headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == booking.id
    assert data["durum"] == BookingDurumu.CANCELLED


async def test_baskasinin_rezervasyonu_iptal_edilemez(client: AsyncClient, sample_data, db):
    uye = sample_data["uye"]
    oturum = sample_data["oturum_gelecek"]

    booking = await rezerve_et(
        db,
        member_id=uye.id,
        session_id=oturum.id,
        now=datetime.now(UTC),
    )
    await db.flush()

    # Başka bir üye oluştur
    baska_uye = Member(telefon="+905330009988", ad="Yabancı Üye")
    db.add(baska_uye)
    await db.flush()

    token = create_access_token(subject=str(baska_uye.id))
    headers = {"Authorization": f"Bearer {token}"}

    response = await client.post(
        f"/api/v1/bookings/{booking.id}/cancel",
        headers=headers,
    )
    assert response.status_code == 403


async def test_waitlist_endpoint_basarili(client: AsyncClient, sample_data, db):
    headers = sample_data["headers"]
    tip = sample_data["tip"]
    egitmen = sample_data["egitmen"]
    salon = Room(ad="Waitlist Salonu")
    db.add(salon)
    await db.flush()

    # Kontenjanı tam dolu ders oluştur
    dolu_oturum = ClassSession(
        baslangic=datetime.now(UTC) + timedelta(days=3),
        class_type_id=tip.id,
        instructor_id=egitmen.id,
        room_id=salon.id,
        kontenjan=1,
        dolu_sayi=1,
    )
    db.add(dolu_oturum)
    await db.flush()

    response = await client.post(
        "/api/v1/waitlist",
        json={"session_id": dolu_oturum.id},
        headers=headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert data["session_id"] == dolu_oturum.id
    assert data["sira"] == 1


async def test_my_summary_endpoint_basarili(client: AsyncClient, sample_data, db):
    headers = sample_data["headers"]
    uye = sample_data["uye"]
    oturum = sample_data["oturum_gelecek"]

    # 1 ders rezerve et (kredi bakiyesi 8 - 1 = 7 kalmalı)
    await rezerve_et(
        db,
        member_id=uye.id,
        session_id=oturum.id,
        now=datetime.now(UTC),
    )
    await db.flush()

    response = await client.get("/api/v1/my/summary", headers=headers)
    assert response.status_code == 200

    data = response.json()
    assert data["id"] == uye.id
    assert data["ad"] == "Ayşe Yılmaz"
    assert data["bakiye"] == 7
    assert len(data["aktif_rezervasyonlar"]) == 1
    assert data["aktif_rezervasyonlar"][0]["session_id"] == oturum.id
    assert len(data["gecmis_rezervasyonlar"]) == 0
