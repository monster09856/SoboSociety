from datetime import timedelta

import pytest
from httpx import ASGITransport, AsyncClient

from app.api.deps import get_current_admin, get_current_member, get_db
from app.core.security import (
    create_access_token,
    decode_access_token,
    send_otp,
    verify_otp,
)
from app.main import app
from app.models.uyelik import Member
from app.services.hatalar import GecersizOTP, GecersizTelefon, GecersizToken
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


# --- Security Unit Testleri ---


def test_token_uretimi_ve_dogrulamasi():
    token = create_access_token(subject="123", is_admin=True)
    payload = decode_access_token(token)

    assert payload["sub"] == "123"
    assert payload["is_admin"] is True


def test_gecersiz_token_hata_verir():
    with pytest.raises(GecersizToken):
        decode_access_token("gecersiz.token.str")


def test_suresi_dolmus_token_hata_verir():
    gecmis = timedelta(minutes=-10)
    token = create_access_token(subject="123", expires_delta=gecmis)
    with pytest.raises(GecersizToken):
        decode_access_token(token)


def test_otp_gonderme_ve_dogrulama():
    tel = "+905316033080"
    kod = send_otp(tel)
    assert len(kod) == 6
    assert verify_otp(tel, kod) is True
    assert verify_otp(tel, "999999") is False
    assert verify_otp(tel, "000000") is False


def test_gecersiz_telefon_otp_gonderilemez():
    with pytest.raises(GecersizTelefon):
        send_otp("12345")


# --- API Endpoint Testleri ---


async def test_otp_send_endpoint_basarili(client: AsyncClient):
    response = await client.post(
        "/api/v1/auth/otp/send",
        json={"telefon": "5316033080"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["telefon"] == "+905316033080"


async def test_otp_send_endpoint_gecersiz_telefon(client: AsyncClient):
    response = await client.post(
        "/api/v1/auth/otp/send",
        json={"telefon": "invalid-phone"},
    )
    assert response.status_code == 400
    data = response.json()
    assert data["hata"] == "GecersizTelefon"


async def test_otp_verify_endpoint_basarili(client: AsyncClient, db):
    tel = "+905316033080"
    kod = send_otp(tel)
    response = await client.post(
        "/api/v1/auth/otp/verify",
        json={"telefon": tel, "kod": kod},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"

    # Veritabanında üye oluştu mu?
    res = await db.execute(
        Member.__table__.select().where(Member.telefon == "+905316033080")
    )
    uye = res.fetchone()
    assert uye is not None


async def test_otp_verify_endpoint_gecersiz_kod(client: AsyncClient):
    response = await client.post(
        "/api/v1/auth/otp/verify",
        json={"telefon": "+905316033080", "kod": "000000"},
    )
    assert response.status_code == 400
    data = response.json()
    assert data["hata"] == "GecersizOTP"


async def test_auth_me_endpoint_basarili(client: AsyncClient, db):
    # Önce üye oluştur
    uye = Member(telefon="+905316033080", ad="Ayşe Yılmaz")
    db.add(uye)
    await db.flush()

    token = create_access_token(subject=uye.id)
    headers = {"Authorization": f"Bearer {token}"}

    response = await client.get("/api/v1/auth/me", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == uye.id
    assert data["telefon"] == "+905316033080"
    assert data["ad"] == "Ayşe Yılmaz"
    assert data["is_admin"] is False


async def test_auth_me_endpoint_yetkisiz(client: AsyncClient):
    # Token olmadan çağrı
    response = await client.get("/api/v1/auth/me")
    assert response.status_code == 401

    # Geçersiz token ile çağrı
    headers = {"Authorization": "Bearer gecersiz.token"}
    response = await client.get("/api/v1/auth/me", headers=headers)
    assert response.status_code == 401


async def test_get_current_admin_dependency(db):
    admin_tel = ayarlar.admin_telefons[0]
    admin_uye = Member(telefon=admin_tel, ad="Admin User")
    normal_uye = Member(telefon="+905331112233", ad="Normal User")
    db.add_all([admin_uye, normal_uye])
    await db.flush()

    # Admin üyeyle get_current_admin çağrısı
    result = await get_current_admin(db=db, current_member=admin_uye)
    assert result.id == admin_uye.id

    # Normal üyeyle get_current_admin çağrısı 403 vermeli
    with pytest.raises(Exception) as exc_info:
        await get_current_admin(db=db, current_member=normal_uye)
    assert "403" in str(exc_info.value)
