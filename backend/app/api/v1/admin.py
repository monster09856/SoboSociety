from datetime import date, datetime, time, timezone

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin, get_db
from app.models import Booking, BookingDurumu, BookingKaynagi, ClassSession, Member
from app.schemas.admin import (
    AttendanceSubmitRequest,
    AttendanceSubmitResponse,
    AttendeeResponse,
    MemberPackageResponse,
    PackageAssignRequest,
    QuickBookingRequest,
    SessionGenerateRequest,
    SessionGenerateResponse,
    TodaySessionResponse,
)
from app.schemas.member import BookingResponse
from app.services.kredi import paket_tanimla
from app.services.program_uretimi import STUDYO_TZ, uret
from app.services.rezervasyon import rezerve_et
from app.services.telefon import normalize_telefon
from app.services.yoklama import yoklama_al

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
    """Üyeye ders paketi tanımlar."""
    baslangic = body.baslangic or datetime.now(timezone.utc).date()
    try:
        uye_paketi = await paket_tanimla(
            db,
            member_id=body.member_id,
            package_id=body.package_id,
            baslangic=baslangic,
        )
        await db.commit()
        await db.refresh(uye_paketi)
        return uye_paketi
    except Exception:
        await db.rollback()
        raise


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
    """Admin için tüm aktif ve gelecek ders oturumlarını listeler."""
    now = datetime.now(timezone.utc)
    stmt = (
        select(ClassSession)
        .where(ClassSession.baslangic >= now)
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
    session = ClassSession(
        baslangic=body.baslangic,
        class_type_id=body.class_type_id,
        instructor_id=body.instructor_id,
        room_id=body.room_id,
        kontenjan=body.kontenjan,
        dolu_sayi=0,
        durum="active",
    )
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return session


@router.delete("/sessions/{session_id}")
async def delete_session(
    session_id: int,
    db: AsyncSession = Depends(get_db),
    current_admin: Member = Depends(get_current_admin),
):
    """Ders oturumunu takvimden siler / iptal eder."""
    res = await db.execute(select(ClassSession).where(ClassSession.id == session_id))
    session = res.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=404, detail="Ders oturumu bulunamadı.")
    
    session.durum = "cancelled"
    await db.commit()
    return {"silindi": True, "session_id": session_id}



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


# --- Admin Member Management & Credit Intervention Endpoints ---

from app.models import StudioEvent, CreditLedger, LedgerTipi
from app.services.kredi import bakiye, hareket_ekle
from app.schemas.admin import (
    MemberUpdateRequest, MemberAdminDetailResponse, MemberSinglePushRequest,
    EventCreateRequest, EventResponse,
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
            (Member.ad.ilike(f"%{search}%")) | (Member.telefon.ilike(f"%{search}%"))
        )
    res = await db.execute(stmt)
    members = res.scalars().all()

    response = []
    for m in members:
        current_bakiye = await bakiye(db, m.id)
        is_adm = m.telefon in ayarlar.admin_telefons
        response.append(
            MemberAdminDetailResponse(
                id=m.id,
                ad=m.ad,
                telefon=m.telefon,
                bakiye=current_bakiye,
                aktif=m.aktif,
                is_admin=is_adm,
            )
        )
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

    if body.bakiye_override is not None:
        current_bakiye = await bakiye(db, member_id)
        fark = body.bakiye_override - current_bakiye
        if fark != 0:
            await hareket_ekle(
                db,
                member_id=member_id,
                tip=LedgerTipi.ADMIN_ADJUST,
                miktar=fark,
                sebep="Yönetici tarafından doğrudan bakiye müdahalesi",
            )

    await db.commit()
    await db.refresh(m)

    new_bakiye = await bakiye(db, m.id)
    is_adm = m.telefon in ayarlar.admin_telefons
    return MemberAdminDetailResponse(
        id=m.id,
        ad=m.ad,
        telefon=m.telefon,
        bakiye=new_bakiye,
        aktif=m.aktif,
        is_admin=is_adm,
    )


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


