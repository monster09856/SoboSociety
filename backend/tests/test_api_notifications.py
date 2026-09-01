import pytest
from httpx import ASGITransport, AsyncClient

from app.api.deps import get_db
from app.core.security import create_access_token
from app.main import app
from app.models import Member


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


@pytest.mark.asyncio
async def test_notifications_and_device_token_endpoints(client: AsyncClient, db):
    # Test üyesi ve token oluştur
    member = Member(telefon="+905331112233", ad="Bildirim Test")
    db.add(member)
    await db.flush()

    token = create_access_token(subject=member.id)
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Device token kaydet
    res_tok = await client.post(
        "/api/v1/my/device-token",
        json={"device_token": "apns-sample-device-token-12345", "platform": "ios"},
        headers=headers,
    )
    assert res_tok.status_code == 200
    assert res_tok.json()["mesaj"] == "Cihaz token'ı kaydedildi"

    # 2. Bildirimleri getir
    res_notif = await client.get("/api/v1/my/notifications", headers=headers)
    assert res_notif.status_code == 200
    data = res_notif.json()
    assert isinstance(data, list)
