from datetime import date, datetime, time, timezone

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin, get_db
from app.models import Booking, BookingDurumu, BookingKaynagi, ClassSession, Member, WaitlistEntry, CreditLedger, LedgerTipi
from app.schemas.admin import (
    AttendanceSubmitRequest,
    AttendanceSubmitResponse,
    AttendeeResponse,
    MemberPackageResponse,
    MemberAdminDetailResponse,
    PackageAssignRequest,
    QuickBookingRequest,
    SessionGenerateRequest,
    SessionGenerateResponse,
    TodaySessionResponse,
)
from app.schemas.member import BookingResponse
from app.services.kredi import paket_tanimla, hareket_ekle
from app.services.program_uretimi import STUDYO_TZ, uret
from app.services.rezervasyon import rezerve_et
from app.services.telefon import normalize_telefon
from app.services.yoklama import yoklama_al
from app.settings import ayarlar

router = APIRouter(
    prefix="/admin",
    tags=["admin"],
    dependencies=[Depends(get_current_admin)],
)


@router.get("/today", response_model=list[TodaySessionResponse])
async def get_today_sessions(
    tarih: date | None = Query(default=None, description="Hedef tarih (YYYY-MM-DD), varsayılan bugün"),
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Bugünün (veya belirtilen tarihin) ders oturumlarını ve katılımcı listelerini döndürür."""
    target_date = tarih or datetime.now(STUDYO_TZ).date()

    start_local = datetime.combine(target_date, time.min, tzinfo=STUDYO_TZ)
    end_local = datetime.combine(target_date, time.max, tzinfo=STUDYO_TZ)

    start_utc = start_local.astimezone(timezone.utc)
    end_utc = end_local.astimezone(timezone.utc)

    stmt = (
        select(ClassSession)
        .where(
            ClassSession.baslangic >= start_utc,
            ClassSession.baslangic <= end_utc,
        )
        .order_by(ClassSession.baslangic)
    )
    res = await db.execute(stmt)
    sessions = res.scalars().all()

    if not sessions:
        return []

    session_ids = [s.id for s in sessions]

    booking_stmt = (
        select(Booking, Member)
        .join(Member, Booking.member_id == Member.id)
        .where(
            Booking.session_id.in_(session_ids),
            Booking.durum != BookingDurumu.CANCELLED,
        )
        .order_by(Booking.id)
    )
    b_res = await db.execute(booking_stmt)
    bookings_with_members = b_res.all()

    attendees_by_session: dict[int, list[AttendeeResponse]] = {s_id: [] for s_id in session_ids}
    for booking, member in bookings_with_members:
        attendee = AttendeeResponse(
            booking_id=booking.id,
            member_id=member.id,
            ad=member.ad,
            telefon=member.telefon,
            durum=booking.durum,
        )
        if booking.session_id in attendees_by_session:
            attendees_by_session[booking.session_id].append(attendee)

    response_list = []
    for s in sessions:
        katilimcilar = attendees_by_session.get(s.id, [])
        response_list.append(
            TodaySessionResponse(
                id=s.id,
                baslangic=s.baslangic,
                kontenjan=s.kontenjan,
                dolu_sayi=s.dolu_sayi,
                durum=s.durum,
                class_type=s.class_type,
                instructor=s.instructor,
                katilimcilar=katilimcilar,
                attendees=katilimcilar,
            )
        )
    return response_list


@router.post("/quick-booking", response_model=BookingResponse)
async def quick_booking(
    body: QuickBookingRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """DM'den gelen üye için tek tıklamayla rezervasyon girilmesini sağlar."""
    now = datetime.now(timezone.utc)
    norm_phone = normalize_telefon(body.telefon)

    try:
        stmt = select(Member).where(Member.telefon == norm_phone)
        res = await db.execute(stmt)
        member = res.scalar_one_or_none()

        if member is None:
            member = Member(
                telefon=norm_phone,
                ad=body.ad or "DM Üyesi",
                aktif=True,
            )
            db.add(member)
            await db.flush()

        if body.package_id is not None:
            await paket_tanimla(
                db,
                member_id=member.id,
                package_id=body.package_id,
                baslangic=now.date(),
            )

        booking = await rezerve_et(
            db,
            member_id=member.id,
            session_id=body.session_id,
            now=now,
            kaynak=BookingKaynagi.ADMIN,
        )
        await db.commit()
        await db.refresh(booking)
        return booking
    except Exception:
        await db.rollback()
        raise


@router.post("/attendance", response_model=AttendanceSubmitResponse)
async def submit_attendance(
    body: AttendanceSubmitRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Dersin yoklamasını toplu olarak kaydeder."""
    now = datetime.now(timezone.utc)
    try:
        sonuc = await yoklama_al(
            db,
            session_id=body.session_id,
            gelen_member_ids=set(body.gelen_member_ids),
            now=now,
        )
        await db.commit()
        return AttendanceSubmitResponse(gelen=sonuc.gelen, gelmeyen=sonuc.gelmeyen)
    except Exception:
        await db.rollback()
        raise


@router.post("/packages/assign", response_model=MemberPackageResponse)
async def assign_package(
    body: PackageAssignRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Üyeye özel veya hazır ders paketi tanımlar."""
    baslangic = body.baslangic or datetime.now(timezone.utc).date()
    try:
        from app.models.kredi import Package
        target_pkg_id = body.package_id
        if body.ozel_paket_adi or body.ozel_ders_adedi:
            custom_name = body.ozel_paket_adi.strip() if body.ozel_paket_adi else "Özel Üye Paketi"
            custom_credits = body.ozel_ders_adedi if (body.ozel_ders_adedi and body.ozel_ders_adedi > 0) else 10
            custom_days = body.ozel_gecerlilik_gun if (body.ozel_gecerlilik_gun and body.ozel_gecerlilik_gun > 0) else 45
            
            pkg = Package(
                ad=custom_name,
                ders_adedi=custom_credits,
                gecerlilik_gun=custom_days,
                fiyat_kurus=0,
                aktif=True,
            )
            db.add(pkg)
            await db.flush()
            target_pkg_id = pkg.id
        
        if target_pkg_id is None:
            target_pkg_id = 1

        uye_paketi = await paket_tanimla(
            db,
            member_id=body.member_id,
            package_id=target_pkg_id,
            baslangic=baslangic,
        )
        await db.commit()
        await db.refresh(uye_paketi)
        return uye_paketi
    except Exception:
        await db.rollback()
        raise


@router.post("/members/{member_id}/packages/{member_package_id}/cancel", response_model=MemberAdminDetailResponse)
async def cancel_member_package_endpoint(
    member_id: int,
    member_package_id: int,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Admin tarafından üyenin aktif paketini iptal eder ve kalan ders bakiyesini sıfırlar."""
    m = await db.get(Member, member_id)
    if not m:
        raise HTTPException(status_code=404, detail="Üye bulunamadı.")

    mp = await db.get(MemberPackage, member_package_id)
    if not mp or mp.member_id != member_id:
        raise HTTPException(status_code=404, detail="Paket kaydı bulunamadı.")

    # 1. Paketin bitiş tarihini bugüne çekerek paketi sonlandır
    mp.bitis = date.today()

    # 2. Üyenin kalan bakiyesini sıfırla
    current_b = await bakiye(db, member_id)
    if current_b > 0:
        await hareket_ekle(
            db,
            member_id=member_id,
            tip=LedgerTipi.ADMIN_ADJUST,
            miktar=-current_b,
            sebep="Aktif ders paketi yönetici tarafından iptal edildi.",
            member_package_id=member_package_id,
        )

    await db.commit()
    return await _build_member_detail_response(db, m)


@router.post("/sessions/generate", response_model=SessionGenerateResponse)
async def generate_sessions(
    body: SessionGenerateRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Şablondan ders oturumları türetir."""
    try:
        uretilen = await uret(
            db,
            baslangic=body.baslangic,
            bitis=body.bitis,
        )
        await db.commit()
        return SessionGenerateResponse(uretilen_oturum_sayisi=uretilen)
    except Exception:
        await db.rollback()
        raise


from app.schemas.admin import SessionCreateRequest
from app.schemas.member import ClassSessionResponse
from fastapi import HTTPException

@router.get("/sessions", response_model=list[ClassSessionResponse])
async def list_admin_sessions(
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Admin için bugün ve gelecekteki tüm aktif ders oturumlarını listeler."""
    now = datetime.now(timezone.utc)
    start_of_today = now.replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(hours=24)
    stmt = (
        select(ClassSession)
        .where(ClassSession.baslangic >= start_of_today, ClassSession.durum != "cancelled")
        .order_by(ClassSession.baslangic)
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())


@router.post("/sessions", response_model=ClassSessionResponse)
async def create_session(
    body: SessionCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Admin paneli üzerinden tekil yeni ders oturumu ekler."""
    from app.models.program import ClassType, Instructor, Room

    ct = (await db.execute(select(ClassType).where(ClassType.id == body.class_type_id))).scalar_one_or_none()
    if not ct:
        ct = (await db.execute(select(ClassType).limit(1))).scalar_one_or_none()
        if not ct:
            ct = ClassType(ad="Barre", kontenjan=5, sure_dk=50, renk="#A2846F")
            db.add(ct)
            await db.flush()
        target_class_type_id = ct.id
    else:
        target_class_type_id = body.class_type_id

    ins = (await db.execute(select(Instructor).where(Instructor.id == body.instructor_id))).scalar_one_or_none()
    if not ins:
        ins = (await db.execute(select(Instructor).limit(1))).scalar_one_or_none()
        if not ins:
            ins = Instructor(ad="Pelin Hoca", biyografi="Barre Eğitmeni", aktif=True)
            db.add(ins)
            await db.flush()
        target_instructor_id = ins.id
    else:
        target_instructor_id = body.instructor_id

    room = (await db.execute(select(Room).limit(1))).scalar_one_or_none()
    if not room:
        room = Room(ad="Main Studio", aktif=True)
        db.add(room)
        await db.flush()

    session = ClassSession(
        baslangic=body.baslangic,
        class_type_id=target_class_type_id,
        instructor_id=target_instructor_id,
        room_id=room.id,
        kontenjan=body.kontenjan,
        dolu_sayi=0,
        durum="active",
    )
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return session


from app.schemas.admin import SessionUpdateRequest

@router.put("/sessions/{session_id}", response_model=ClassSessionResponse)
async def update_session_endpoint(
    session_id: int,
    body: SessionUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Mevcut bir ders oturumunun tarihini, saatini, eğitmenini veya kontenjanını günceller."""
    res = await db.execute(select(ClassSession).where(ClassSession.id == session_id))
    session = res.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Ders oturumu bulunamadı.")
    
    if body.baslangic is not None:
        session.baslangic = body.baslangic
    if body.class_type_id is not None:
        session.class_type_id = body.class_type_id
    if body.instructor_id is not None:
        session.instructor_id = body.instructor_id
    if body.kontenjan is not None:
        session.kontenjan = body.kontenjan

    await db.commit()
    await db.refresh(session)
    return session


@router.delete("/sessions/{session_id}")
async def delete_session_endpoint(
    session_id: int,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Takvimdeki bir ders oturumunu siler/iptal eder ve varsa kayıtlı üyelerin kredilerini iade eder."""
    res = await db.execute(select(ClassSession).where(ClassSession.id == session_id))
    session = res.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Ders oturumu bulunamadı.")

    # 1. Bu derse kayıtlı rezervasyonları bul
    res_bookings = await db.execute(
        select(Booking).where(Booking.session_id == session_id, Booking.durum == BookingDurumu.BOOKED)
    )
    bookings = res_bookings.scalars().all()

    # 2. Kayıtlı üyelerin kredilerini iade et ve bildirim gönder
    for b in bookings:
        b.durum = BookingDurumu.CANCELLED
        b.cancelled_at = datetime.now(timezone.utc)
        await hareket_ekle(
            db,
            member_id=b.member_id,
            tip=LedgerTipi.CANCEL_REFUND,
            miktar=1,
            sebep=f"Ders yönetici tarafından iptal edildi",
            booking_id=b.id,
        )
        await bildirim_gonder(
            db,
            member_id=b.member_id,
            baslik="ℹ️ Ders İptali Uyarısı",
            mesaj=f"Kayıtlı olduğunuz ders stüdyo yönetimi tarafından iptal edilmiştir. Ders krediniz hesabınıza iade edildi.",
            tip="DERS_IPTALI",
        )

    # 3. Bekleme listesini temizle
    await db.execute(
        delete(WaitlistEntry).where(WaitlistEntry.session_id == session_id)
    )

    # 4. Oturumu sil
    await db.delete(session)
    await db.commit()

    return {"mesaj": "Ders oturumu başarıyla takvimden silindi.", "iptal_edilen_kayit": len(bookings)}




# --- Self-Hosted Firebase Push Campaign Console Endpoints ---

from pydantic import BaseModel
from app.models.bildirim import NotificationCampaign
from app.services.bildirim import bildirim_gonder


class BroadcastRequest(BaseModel):
    baslik: str
    mesaj: str
    hedef_kitle: str = "TUM_UYELER"


class CampaignCreateRequest(BaseModel):
    baslik: str
    mesaj: str
    hedef_kitle: str = "TUM_UYELER"
    zamanlama_tipi: str = "GUNLUK_TEKRAR"
    zamanlama_saat: str = "10:00"


@router.post("/notifications/broadcast")
async def broadcast_push_notification(
    body: BroadcastRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Anında tüm üyelere veya hedef kitleye Firebase/APNs Push Bildirimi gönderir."""
    res = await db.execute(select(Member).where(Member.aktif == True))
    members = res.scalars().all()

    gonderilen = 0
    for m in members:
        await bildirim_gonder(
            db,
            member_id=m.id,
            baslik=body.baslik,
            mesaj=body.mesaj,
            tip="DUYURU",
        )
        gonderilen += 1

    await db.commit()
    return {"mesaj": "Toplu bildirim gönderildi", "gonderilen_sayisi": gonderilen}


@router.get("/notifications/campaigns")
async def get_notification_campaigns(
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Zamanlanmış veya günlük tekrarlayan bildirim kampanyalarını getirir."""
    res = await db.execute(select(NotificationCampaign).order_by(NotificationCampaign.id.desc()))
    items = res.scalars().all()
    return [
        {
            "id": c.id,
            "baslik": c.baslik,
            "mesaj": c.mesaj,
            "hedef_kitle": c.hedef_kitle,
            "zamanlama_tipi": c.zamanlama_tipi,
            "zamanlama_saat": c.zamanlama_saat,
            "gonderilen_sayisi": c.gonderilen_sayisi,
            "aktif": c.aktif,
        }
        for c in items
    ]


@router.post("/notifications/campaigns")
async def create_notification_campaign(
    body: CampaignCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Yeni bir günlük veya zamanlanmış bildirim kampanyası oluşturur."""
    c = NotificationCampaign(
        baslik=body.baslik,
        mesaj=body.mesaj,
        hedef_kitle=body.hedef_kitle,
        zamanlama_tipi=body.zamanlama_tipi,
        zamanlama_saat=body.zamanlama_saat,
        aktif=True,
    )
    db.add(c)
    await db.commit()
    await db.refresh(c)
    return {"mesaj": "Kampanya oluşturuldu", "id": c.id}


@router.delete("/notifications/campaigns/{campaign_id}")
async def delete_notification_campaign(
    campaign_id: int,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Kampanyayı siler."""
    res = await db.execute(select(NotificationCampaign).where(NotificationCampaign.id == campaign_id))
    c = res.scalar_one_or_none()
    if c:
        await db.delete(c)
        await db.commit()
    return {"mesaj": "Kampanya silindi"}


from app.schemas.admin import AdminCredentialsUpdateRequest
from app.core.security import hash_password

@router.put("/credentials")
async def update_admin_credentials_endpoint(
    body: AdminCredentialsUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Yöneticinin kendi kullanıcı adı ve şifresini değiştirmesini sağlar."""
    if body.yeni_kullanici_adi and body.yeni_kullanici_adi.strip():
        new_username = body.yeni_kullanici_adi.strip().lower()
        if len(new_username) < 3:
            raise HTTPException(status_code=400, detail="Kullanıcı adı en az 3 karakter olmalıdır.")
        
        stmt = select(Member).where(Member.kullanici_adi.ilike(new_username), Member.id != current_admin.id)
        res = await db.execute(stmt)
        if res.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Bu kullanıcı adı başka bir hesap tarafından kullanılıyor.")
        
        current_admin.kullanici_adi = new_username

    if len(body.yeni_sifre.strip()) < 4:
        raise HTTPException(status_code=400, detail="Yeni şifre en az 4 karakter olmalıdır.")

    current_admin.sifre_hash = hash_password(body.yeni_sifre.strip())
    await db.commit()
    await db.refresh(current_admin)

    return {
        "mesaj": "Yönetici giriş bilgileri başarıyla güncellendi.",
        "kullanici_adi": current_admin.kullanici_adi,
    }


# --- Admin Member Management & Credit Intervention Endpoints ---

from app.models import StudioEvent, CreditLedger, LedgerTipi, MemberPackage, Package
from app.services.kredi import bakiye, hareket_ekle
from app.schemas.admin import (
    MemberUpdateRequest, MemberAdminDetailResponse, MemberSinglePushRequest,
    EventCreateRequest, EventResponse,
)

async def _build_member_detail_response(db: AsyncSession, m: Member) -> MemberAdminDetailResponse:
    current_bakiye = await bakiye(db, m.id)
    is_adm = (m.telefon in ayarlar.admin_telefons) or (m.kullanici_adi == "admin")
    
    mp_res = await db.execute(
        select(MemberPackage, Package)
        .join(Package, MemberPackage.package_id == Package.id)
        .where(MemberPackage.member_id == m.id)
        .order_by(MemberPackage.id.desc())
    )
    mp_rows = mp_res.all()

    aktif_mp_id = None
    aktif_pkg_ad = None
    pkg_bitis_str = None
    kalan_gun = None
    pkg_history = []

    today = date.today()
    for mp, p in mp_rows:
        pkg_name = getattr(mp, "ozel_paket_adi", None) or (p.ad if p else "Stüdyo Ders Paketi")
        ders_sayisi = getattr(mp, "ders_adedi", p.ders_adedi if p else 0)
        bitis_str = mp.bitis.strftime('%d.%m.%Y') if mp.bitis else ""
        pkg_history.append(f"{pkg_name} ({ders_sayisi} Ders / Bitiş: {bitis_str})")
        if mp.baslangic and mp.bitis and mp.baslangic <= today < mp.bitis and aktif_pkg_ad is None:
            aktif_mp_id = mp.id
            aktif_pkg_ad = pkg_name
            pkg_bitis_str = bitis_str
            kalan_gun = (mp.bitis - today).days

    return MemberAdminDetailResponse(
        id=m.id,
        ad=m.ad,
        kullanici_adi=m.kullanici_adi,
        telefon=m.telefon,
        bakiye=current_bakiye,
        aktif=m.aktif,
        is_admin=is_adm,
        bel=m.bel,
        kalca=m.kalca,
        sag_ic_bacak=m.sag_ic_bacak,
        sag_bacak=m.sag_bacak,
        sol_ic_bacak=m.sol_ic_bacak,
        sol_bacak=m.sol_bacak,
        sag_kol=m.sag_kol,
        sol_kol=m.sol_kol,
        boy=m.boy,
        kilo=m.kilo,
        saglik_notu=m.saglik_notu,
        aktif_member_package_id=aktif_mp_id,
        aktif_paket_adi=aktif_pkg_ad,
        paket_bitis_tarihi=pkg_bitis_str,
        kalan_gun_sayisi=kalan_gun,
        tanimlanan_paketler=pkg_history,
    )


@router.get("/members", response_model=list[MemberAdminDetailResponse])
async def list_admin_members(
    search: str | None = None,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Admin için stüdyodaki tüm üyeleri, bakiyelerini ve durumlarını listeler."""
    stmt = select(Member).order_by(Member.id.desc())
    if search:
        stmt = stmt.where(
            (Member.ad.ilike(f"%{search}%"))
            | (Member.kullanici_adi.ilike(f"%{search}%"))
            | (Member.telefon.ilike(f"%{search}%"))
        )
    res = await db.execute(stmt)
    members = res.scalars().all()

    response = []
    for m in members:
        detail = await _build_member_detail_response(db, m)
        response.append(detail)
    return response


@router.put("/members/{member_id}", response_model=MemberAdminDetailResponse)
async def update_admin_member(
    member_id: int,
    body: MemberUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Admin üye bilgilerini düzenler, durumunu değiştirir veya elle bakiye müdahalesi yapar."""
    m = await db.get(Member, member_id)
    if not m:
        raise HTTPException(status_code=404, detail="Üye bulunamadı.")

    if body.ad is not None:
        m.ad = body.ad
    if body.telefon is not None:
        m.telefon = normalize_telefon(body.telefon)
    if body.aktif is not None:
        m.aktif = body.aktif

    measurement_fields = [
        "bel", "kalca", "sag_ic_bacak", "sag_bacak",
        "sol_ic_bacak", "sol_bacak", "sag_kol", "sol_kol",
        "boy", "kilo", "saglik_notu"
    ]
    for f in measurement_fields:
        val = getattr(body, f, None)
        if val is not None:
            setattr(m, f, val.strip() if isinstance(val, str) else val)

    if body.bakiye_override is not None:
        current_bakiye = await bakiye(db, member_id)
        fark = body.bakiye_override - current_bakiye
        if fark != 0:
            await hareket_ekle(
                db,
                member_id=member_id,
                tip=LedgerTipi.ADMIN_ADJUST,
                miktar=fark,
                sebep=f"Admin tarafından bakiye {current_bakiye} -> {body.bakiye_override} olarak manuel güncellendi.",
            )

    await db.commit()
    await db.refresh(m)

    return await _build_member_detail_response(db, m)


@router.post("/members/{member_id}/send-notification")
async def send_single_member_notification(
    member_id: int,
    body: MemberSinglePushRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Spesifik tek bir üyeye özel push bildirimi / duyuru gönderir."""
    m = await db.get(Member, member_id)
    if not m:
        raise HTTPException(status_code=404, detail="Üye bulunamadı.")

    await bildirim_gonder(
        db,
        member_id=m.id,
        baslik=body.baslik,
        mesaj=body.mesaj,
        tip="KISIYE_OZEL",
    )
    await db.commit()
    return {"mesaj": f"{m.ad} üyesine özel bildirim gönderildi.", "member_id": m.id}


# --- Admin Events & Workshops Endpoints ---

@router.get("/events", response_model=list[EventResponse])
async def list_admin_events(
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Admin paneli için tüm stüdyo etkinliklerini ve workshop'ları listeler."""
    res = await db.execute(select(StudioEvent).order_by(StudioEvent.tarih_saat.desc()))
    return list(res.scalars().all())


@router.post("/events", response_model=EventResponse)
async def create_admin_event(
    body: EventCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Yeni bir Workshop veya Etkinlik ekler."""
    ev = StudioEvent(
        baslik=body.baslik,
        turu=body.turu,
        tarih_saat=body.tarih_saat,
        aciklama=body.aciklama,
        kontenjan=body.kontenjan,
        ucret=body.ucret,
        aktif=True,
    )
    db.add(ev)
    await db.commit()
    await db.refresh(ev)
    return ev


@router.delete("/events/{event_id}")
async def delete_admin_event(
    event_id: int,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Etkinliği / Workshop'u siler."""
    ev = await db.get(StudioEvent, event_id)
    if not ev:
        raise HTTPException(status_code=404, detail="Etkinlik bulunamadı.")
    
    await db.delete(ev)
    await db.commit()
    return {"silindi": True, "event_id": event_id}


# --- Dynamic Class Types & Instructors Endpoints ---

from pydantic import BaseModel

class ClassTypeCreateRequest(BaseModel):
    ad: str
    sure_dk: int = 50
    kontenjan: int = 5
    renk: str = "#A2846F"

class InstructorCreateRequest(BaseModel):
    ad: str
    biyografi: str | None = None
    foto_url: str | None = None

@router.get("/class-types")
async def list_class_types(
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Tüm aktif ders tiplerini listeler."""
    from app.models.program import ClassType
    res = await db.execute(select(ClassType).where(ClassType.aktif == True).order_by(ClassType.id))
    return list(res.scalars().all())

@router.post("/class-types")
async def create_class_type(
    body: ClassTypeCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Yeni ders tipi ekler (ör. Reformer Pilates, Zumba, HIIT)."""
    from app.models.program import ClassType
    ad_clean = body.ad.strip()
    existing = (await db.execute(select(ClassType).where(ClassType.ad.ilike(ad_clean)))).scalar_one_or_none()
    if existing:
        return existing
    
    ct = ClassType(
        ad=ad_clean,
        sure_dk=body.sure_dk,
        kontenjan=body.kontenjan,
        renk=body.renk,
        aktif=True,
    )
    db.add(ct)
    await db.commit()
    await db.refresh(ct)
    return ct

@router.get("/instructors")
async def list_instructors(
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Tüm aktif eğitmenleri listeler."""
    from app.models.uyelik import Instructor
    res = await db.execute(select(Instructor).where(Instructor.aktif == True).order_by(Instructor.id))
    return list(res.scalars().all())

@router.post("/instructors")
async def create_instructor(
    body: InstructorCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Yeni eğitmen ekler (ör. Selin Yılmaz)."""
    from app.models.uyelik import Instructor
    ad_clean = body.ad.strip()
    existing = (await db.execute(select(Instructor).where(Instructor.ad.ilike(ad_clean)))).scalar_one_or_none()
    if existing:
        return existing
    
    ins = Instructor(
        ad=ad_clean,
        biyografi=body.biyografi,
        foto_url=body.foto_url,
        aktif=True,
    )
    db.add(ins)
    await db.commit()
    await db.refresh(ins)
    return ins


