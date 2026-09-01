from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo

import pytest
from httpx import ASGITransport, AsyncClient

from app.api.deps import get_db
from app.main import app
from app.models import (
    BookingDurumu,
    ClassSession,
    ClassType,
    Instructor,
    Member,
    Package,
    Room,
    ScheduleTemplate,
)
from app.core.security import _OTP_STORE, send_otp
from app.services.telefon import normalize_telefon
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


async def test_e2e_full_flow(client: AsyncClient, db):
    """Tam uçtan uca senaryoyu HTTP API seviyesinde test eder:

    - Adım 1: Üye OTP ile JWT token alır (ve Admin de JWT token alır).
    - Adım 2: Admin üye için paket tanımlar (/api/v1/admin/packages/assign).
    - Adım 3: Admin şablondan haftalık oturum türetir (/api/v1/admin/sessions/generate).
    - Adım 4: Üye /api/v1/sessions ile açılan dersleri sorgular ve POST /api/v1/bookings ile yerini ayırtır.
    - Adım 5: Admin /api/v1/admin/today çağrısıyla derse kayıtlı katılımcıları listeler ve üyenin listede olduğunu görür.
    - Adım 6: Admin DM'den gelen ikinci bir üye için telefon numarasıyla hızlı rezervasyon yapar (/api/v1/admin/quick-booking).
    - Adım 7: Admin ders tamamlandıktan sonra /api/v1/admin/attendance ile yoklama alır (biri katıldı, biri gelmedi).
    - Adım 8: Üye /api/v1/my/summary ile kalan kredisini ve ders geçmişindeki güncellenmiş durumu (attended / no_show) doğrular.
    """

    # --- Pre-requisites & Master Data Setup ---
    tip = ClassType(ad="Reformer Pilates", kontenjan=5, sure_dk=50, aktif=True)
    egitmen = Instructor(ad="Deniz Hoca", aktif=True)
    salon = Room(ad="Ana Salon", aktif=True)
    paket = Package(
        ad="10 Derslik Paket",
        ders_adedi=10,
        gecerlilik_gun=30,
        fiyat_kurus=500000,
    )
    db.add_all([tip, egitmen, salon, paket])
    await db.flush()

    # --- Adım 1: Üye ve Admin OTP / Auth ---
    # Admin Girişi
    admin_tel = ayarlar.admin_telefons[0]
    res_admin_send = await client.post(
        "/api/v1/auth/otp/send", json={"telefon": admin_tel}
    )
    assert res_admin_send.status_code == 200
    kod_admin = _OTP_STORE[normalize_telefon(admin_tel)]

    res_admin_verify = await client.post(
        "/api/v1/auth/otp/verify",
        json={"telefon": admin_tel, "kod": kod_admin},
    )
    assert res_admin_verify.status_code == 200
    admin_token = res_admin_verify.json()["access_token"]
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    # Üye 1 Girişi
    member_1_tel = "05321002030"
    res_m1_send = await client.post(
        "/api/v1/auth/otp/send", json={"telefon": member_1_tel}
    )
    assert res_m1_send.status_code == 200
    kod_m1 = _OTP_STORE[normalize_telefon(member_1_tel)]

    res_m1_verify = await client.post(
        "/api/v1/auth/otp/verify",
        json={"telefon": "+905321002030", "kod": kod_m1},
    )
    assert res_m1_verify.status_code == 200
    m1_token = res_m1_verify.json()["access_token"]
    m1_headers = {"Authorization": f"Bearer {m1_token}"}

    # Üye 1 profil sorgusu
    res_m1_me = await client.get("/api/v1/auth/me", headers=m1_headers)
    assert res_m1_me.status_code == 200
    m1_data = res_m1_me.json()
    member_1_id = m1_data["id"]
    assert m1_data["telefon"] == "+905321002030"
    assert m1_data["is_admin"] is False

    # --- Adım 2: Admin üye için paket tanımlar ---
    assign_payload = {
        "member_id": member_1_id,
        "package_id": paket.id,
        "baslangic": str(date.today()),
    }
    res_assign = await client.post(
        "/api/v1/admin/packages/assign",
        json=assign_payload,
        headers=admin_headers,
    )
    assert res_assign.status_code == 200
    assign_data = res_assign.json()
    assert assign_data["member_id"] == member_1_id
    assert assign_data["package_id"] == paket.id

    # --- Adım 3: Admin şablondan haftalık oturum türetir ---
    today = date.today()
    now_ist = datetime.now(ZoneInfo("Europe/Istanbul"))
    saat_dk = min(23 * 60 + 59, now_ist.hour * 60 + now_ist.minute + 60)

    sablon = ScheduleTemplate(
        hafta_gunu=today.weekday(),
        saat_dk=saat_dk,
        class_type_id=tip.id,
        instructor_id=egitmen.id,
        room_id=salon.id,
        gecerli_baslangic=today - timedelta(days=1),
    )
    db.add(sablon)
    await db.flush()

    generate_payload = {
        "baslangic": str(today),
        "bitis": str(today),
    }
    res_generate = await client.post(
        "/api/v1/admin/sessions/generate",
        json=generate_payload,
        headers=admin_headers,
    )
    assert res_generate.status_code == 200
    generate_data = res_generate.json()
    assert generate_data["uretilen_oturum_sayisi"] >= 1

    # --- Adım 4: Üye /api/v1/sessions ile açılan dersleri sorgular ve POST /api/v1/bookings ile yerini ayırtır ---
    res_sessions = await client.get("/api/v1/sessions", headers=m1_headers)
    assert res_sessions.status_code == 200
    sessions = res_sessions.json()
    assert len(sessions) >= 1
    session_id = sessions[0]["id"]

    booking_payload = {"session_id": session_id}
    res_booking = await client.post(
        "/api/v1/bookings", json=booking_payload, headers=m1_headers
    )
    assert res_booking.status_code == 200
    booking_1_data = res_booking.json()
    booking_1_id = booking_1_data["id"]
    assert booking_1_data["member_id"] == member_1_id
    assert booking_1_data["session_id"] == session_id
    assert booking_1_data["durum"] == BookingDurumu.BOOKED.value

    # --- Adım 5: Admin /api/v1/admin/today çağrısıyla derse kayıtlı katılımcıları listeler ---
    res_today = await client.get("/api/v1/admin/today", headers=admin_headers)
    assert res_today.status_code == 200
    today_sessions = res_today.json()
    target_session = next((s for s in today_sessions if s["id"] == session_id), None)
    assert target_session is not None
    katilimci_ids = [k["member_id"] for k in target_session["katilimcilar"]]
    assert member_1_id in katilimci_ids

    # --- Adım 6: Admin DM'den gelen ikinci bir üye için telefon numarasıyla hızlı rezervasyon yapar ---
    member_2_phone = "05359998877"
    quick_payload = {
        "telefon": member_2_phone,
        "ad": "DM Müşterisi Selin",
        "session_id": session_id,
        "package_id": paket.id,
    }
    res_quick = await client.post(
        "/api/v1/admin/quick-booking", json=quick_payload, headers=admin_headers
    )
    assert res_quick.status_code == 200
    quick_data = res_quick.json()
    member_2_id = quick_data["member_id"]
    booking_2_id = quick_data["id"]
    assert quick_data["session_id"] == session_id
    assert quick_data["durum"] == BookingDurumu.BOOKED.value
    assert quick_data["kaynak"] == "admin"

    # --- Adım 7: Admin ders tamamlandıktan sonra /api/v1/admin/attendance ile yoklama alır ---
    oturum_obj = await db.get(ClassSession, session_id)
    oturum_obj.baslangic = datetime.now(timezone.utc) - timedelta(minutes=30)
    await db.flush()

    attendance_payload = {
        "session_id": session_id,
        "gelen_member_ids": [member_1_id],
    }
    res_attendance = await client.post(
        "/api/v1/admin/attendance",
        json=attendance_payload,
        headers=admin_headers,
    )
    assert res_attendance.status_code == 200
    att_data = res_attendance.json()
    assert att_data["gelen"] == 1
    assert att_data["gelmeyen"] == 1

    # --- Adım 8: Üye /api/v1/my/summary ile kalan kredisini ve ders geçmişindeki güncellenmiş durumu doğrular ---
    # Üye 1 (Katıldı / Attended)
    res_summary_1 = await client.get("/api/v1/my/summary", headers=m1_headers)
    assert res_summary_1.status_code == 200
    summary_1 = res_summary_1.json()
    assert summary_1["bakiye"] == 9
    gecmis_1 = summary_1["gecmis_rezervasyonlar"]
    b1_record = next((b for b in gecmis_1 if b["id"] == booking_1_id), None)
    assert b1_record is not None
    assert b1_record["durum"] == BookingDurumu.ATTENDED.value

    # Üye 2 (Gelmeyi Unuttu / No-Show)
    kod_m2 = send_otp("+905359998877")
    res_m2_verify = await client.post(
        "/api/v1/auth/otp/verify",
        json={"telefon": "+905359998877", "kod": kod_m2},
    )
    assert res_m2_verify.status_code == 200
    m2_token = res_m2_verify.json()["access_token"]
    m2_headers = {"Authorization": f"Bearer {m2_token}"}

    res_summary_2 = await client.get("/api/v1/my/summary", headers=m2_headers)
    assert res_summary_2.status_code == 200
    summary_2 = res_summary_2.json()
    assert summary_2["bakiye"] == 9
    gecmis_2 = summary_2["gecmis_rezervasyonlar"]
    b2_record = next((b for b in gecmis_2 if b["id"] == booking_2_id), None)
    assert b2_record is not None
    assert b2_record["durum"] == BookingDurumu.NO_SHOW.value
