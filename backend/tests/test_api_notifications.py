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


@pytest.mark.asyncio
async def test_single_member_notification_flow(client: AsyncClient, db):
    # 1. Admin & Normal Üye oluştur
    admin_user = Member(telefon="05316033080", ad="Admin User", kullanici_adi="admin")
    target_member = Member(telefon="+905559998877", ad="Target Member", kullanici_adi="target_user")
    db.add_all([admin_user, target_member])
    await db.flush()

    admin_token = create_access_token(subject=admin_user.id, is_admin=True)
    member_token = create_access_token(subject=target_member.id, is_admin=False)

    admin_headers = {"Authorization": f"Bearer {admin_token}"}
    member_headers = {"Authorization": f"Bearer {member_token}"}

    # 2. Admin üyeye özel bildirim göndersin
    res_send = await client.post(
        f"/api/v1/admin/members/{target_member.id}/send-notification",
        json={"baslik": "Özel Ders Hediyesi", "mesaj": "Sayın Target Member, hesabınıza 1 özel ders tanımlandı."},
        headers=admin_headers,
    )
    assert res_send.status_code == 200
    assert res_send.json()["member_id"] == target_member.id

    # 3. Üye bildirim kutusunu sorgulasın
    res_my_notifs = await client.get("/api/v1/my/notifications", headers=member_headers)
    assert res_my_notifs.status_code == 200
    notifs = res_my_notifs.json()
    assert len(notifs) >= 1
    target_notif = notifs[0]
    assert target_notif["baslik"] == "Özel Ders Hediyesi"
    assert target_notif["mesaj"] == "Sayın Target Member, hesabınıza 1 özel ders tanımlandı."
    assert target_notif["tip"] == "KISIYE_OZEL"
    assert target_notif["okundu"] is False
