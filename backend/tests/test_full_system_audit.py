import pytest
from datetime import datetime, date, timedelta, timezone
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.api.deps import get_db
from app.core.security import create_access_token
from app.models import Member, ClassSession, ClassType, Instructor, Room, MemberPackage, Package, CreditLedger, LedgerTipi, Booking, BookingDurumu
from app.settings import ayarlar
from sqlalchemy import select, delete


@pytest.mark.asyncio
async def test_full_system_audit(db):
    """Geniş Kapsamlı Sistem Denetimi Testi:
    Tüm Admin ve Üye API endpoint'lerini tek tek çağırıp HTTP 500 hatası üretmediğini doğrular.
    """
    async def override_get_db():
        yield db

    app.dependency_overrides[get_db] = override_get_db

    try:
        admin_phone = ayarlar.admin_telefons[0]
        res_admin = await db.execute(select(Member).where(Member.telefon == admin_phone))
        admin = res_admin.scalars().first()
        if not admin:
            admin = Member(ad="Test Admin", telefon=admin_phone, kullanici_adi="admin", aktif=True)
            db.add(admin)
            await db.flush()

        res_member = await db.execute(select(Member).where(Member.telefon != admin_phone))
        member = res_member.scalars().first()
        if not member:
            member = Member(ad="Test Member", telefon="+905441112233", kullanici_adi="testmember", aktif=True)
            db.add(member)
            await db.flush()

        # ClassType, Instructor, Room hazırla
        ct = (await db.execute(select(ClassType))).scalars().first()
        if not ct:
            ct = ClassType(ad="Audited Barre", kontenjan=5, sure_dk=50, renk="#A2846F")
            db.add(ct)
            await db.flush()

        ins = (await db.execute(select(Instructor))).scalars().first()
        if not ins:
            ins = Instructor(ad="Audited Hoca", biyografi="Eğitmen", aktif=True)
            db.add(ins)
            await db.flush()

        room = (await db.execute(select(Room))).scalars().first()
        if not room:
            room = Room(ad="Audited Room", aktif=True)
            db.add(room)
            await db.flush()

        # ClassSession hazırla (Gelecekteki ders)
        sess = ClassSession(
            baslangic=datetime.now(timezone.utc) + timedelta(days=1),
            class_type_id=ct.id,
            instructor_id=ins.id,
            room_id=room.id,
            kontenjan=5,
            dolu_sayi=0,
            durum="active"
        )
        db.add(sess)

        # Past ClassSession (Yoklama alınabilir ders)
        past_sess = ClassSession(
            baslangic=datetime.now(timezone.utc) - timedelta(hours=1),
            class_type_id=ct.id,
            instructor_id=ins.id,
            room_id=room.id,
            kontenjan=5,
            dolu_sayi=0,
            durum="active"
        )
        db.add(past_sess)

        # Package hazırla
        pkg = (await db.execute(select(Package))).scalars().first()
        if not pkg:
            pkg = Package(ad="Audited Test Paket", ders_adedi=8, gecerlilik_gun=30, fiyat_kurus=100000, aktif=True)
            db.add(pkg)
            await db.flush()

        # MemberPackage hazırla
        mp = MemberPackage(
            member_id=member.id,
            package_id=pkg.id,
            baslangic=date.today(),
            bitis=date.today() + timedelta(days=30)
        )
        db.add(mp)
        await db.commit()
        await db.refresh(admin)
        await db.refresh(member)
        await db.refresh(sess)
        await db.refresh(past_sess)
        await db.refresh(mp)

        admin_token = create_access_token(subject=str(admin.id), is_admin=True)
        member_token = create_access_token(subject=str(member.id), is_admin=False)

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://testserver") as client:
            admin_headers = {"Authorization": f"Bearer {admin_token}"}
            member_headers = {"Authorization": f"Bearer {member_token}"}

            # 1. Class Types & Instructors
            r = await client.get("/api/v1/admin/class-types", headers=admin_headers)
            assert r.status_code == 200, f"GET /admin/class-types failed: {r.text}"

            r = await client.get("/api/v1/admin/instructors", headers=admin_headers)
            assert r.status_code == 200, f"GET /admin/instructors failed: {r.text}"

            # 2. Get Admin Sessions
            r = await client.get("/api/v1/admin/sessions", headers=admin_headers)
            assert r.status_code == 200, f"GET /admin/sessions failed: {r.text}"

            # 3. Create Session
            new_session_payload = {
                "class_type_id": ct.id,
                "instructor_id": ins.id,
                "baslangic": (datetime.now(timezone.utc) + timedelta(days=2)).isoformat(),
                "kontenjan": 5
            }
            r = await client.post("/api/v1/admin/sessions", json=new_session_payload, headers=admin_headers)
            assert r.status_code in (200, 201), f"POST /admin/sessions failed: {r.text}"
            created_session_id = r.json()["id"]

            # 4. Update Session
            update_payload = {"kontenjan": 6}
            r = await client.put(f"/api/v1/admin/sessions/{created_session_id}", json=update_payload, headers=admin_headers)
            assert r.status_code == 200, f"PUT /admin/sessions/{created_session_id} failed: {r.text}"

            # 5. Delete Session
            r = await client.delete(f"/api/v1/admin/sessions/{created_session_id}", headers=admin_headers)
            assert r.status_code == 200, f"DELETE /admin/sessions/{created_session_id} failed: {r.text}"

            # 6. Get Today Sessions
            today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
            r = await client.get(f"/api/v1/admin/today?tarih={today_str}", headers=admin_headers)
            assert r.status_code == 200, f"GET /admin/today failed: {r.text}"

            # 7. Member List in Admin
            r = await client.get("/api/v1/admin/members", headers=admin_headers)
            assert r.status_code == 200, f"GET /admin/members failed: {r.text}"

            # 8. Update Member Detail / Measurements in Admin
            update_member_payload = {
                "bel": "65",
                "kalca": "95",
                "kilo": "58",
                "saglik_notu": "Bel fıtığı hassasiyeti var"
            }
            r = await client.put(f"/api/v1/admin/members/{member.id}", json=update_member_payload, headers=admin_headers)
            assert r.status_code == 200, f"PUT /admin/members/{member.id} failed: {r.text}"

            # 9. Cancel Member Active Package
            r = await client.post(f"/api/v1/admin/members/{member.id}/packages/{mp.id}/cancel", headers=admin_headers)
            assert r.status_code == 200, f"POST /admin/members/.../cancel failed: {r.text}"

            # 10. Assign Package to Member
            assign_payload = {
                "member_id": member.id,
                "package_id": pkg.id,
                "ders_sayisi": 8,
                "gecerlilik_gun": 30
            }
            r = await client.post("/api/v1/admin/packages/assign", json=assign_payload, headers=admin_headers)
            assert r.status_code == 200, f"POST /admin/packages/assign failed: {r.text}"

            # 11. Quick Booking
            quick_payload = {
                "session_id": sess.id,
                "telefon": member.telefon or "05412656138"
            }
            r = await client.post("/api/v1/admin/quick-booking", json=quick_payload, headers=admin_headers)
            assert r.status_code in (200, 201), f"POST /admin/quick-booking failed: {r.text}"

            # 12. Attendance Submit for Past Session
            attendance_payload = {
                "session_id": past_sess.id,
                "gelen_member_ids": [member.id]
            }
            r = await client.post("/api/v1/admin/attendance", json=attendance_payload, headers=admin_headers)
            assert r.status_code == 200, f"POST /admin/attendance failed: {r.text}"

            # 13. Member Get Sessions
            r = await client.get("/api/v1/sessions", headers=member_headers)
            assert r.status_code == 200, f"GET /sessions failed: {r.text}"

            # 14. Member Summary
            r = await client.get("/api/v1/my/summary", headers=member_headers)
            assert r.status_code == 200, f"GET /my/summary failed: {r.text}"
    finally:
        app.dependency_overrides.clear()
