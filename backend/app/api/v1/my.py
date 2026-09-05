from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_member, get_db
from app.models.rezervasyon import Booking, BookingDurumu
from app.models.uyelik import Member, MemberMeasurementHistory
from app.schemas.member import (
    MeasurementCreateRequest,
    MeasurementHistoryResponse,
    MemberStatsResponse,
    MemberSummaryResponse,
)
from app.services.kredi import bakiye

router = APIRouter(prefix="/my", tags=["my"])


@router.get("/summary", response_model=MemberSummaryResponse)
async def get_my_summary(
    db: AsyncSession = Depends(get_db),
    current_member: Member = Depends(get_current_member),
):
    """Giriş yapmış üyenin bakiye ve rezervasyon özetini döndürür."""
    kredi_bakiye = await bakiye(db, current_member.id)
    now = datetime.now(timezone.utc)

    stmt = (
        select(Booking)
        .where(Booking.member_id == current_member.id)
        .order_by(Booking.id.desc())
    )
    result = await db.execute(stmt)
    bookings = list(result.scalars().all())

    aktif = []
    gecmis = []
    for b in bookings:
        if b.durum == BookingDurumu.BOOKED and (b.session is None or b.session.baslangic >= now):
            aktif.append(b)
        else:
            gecmis.append(b)

    return MemberSummaryResponse(
        id=current_member.id,
        ad=current_member.ad,
        kullanici_adi=current_member.kullanici_adi,
        telefon=current_member.telefon or "",
        bakiye=kredi_bakiye,
        aktif_rezervasyonlar=aktif,
        gecmis_rezervasyonlar=gecmis,
    )


@router.get("/stats", response_model=MemberStatsResponse)
async def get_my_stats(
    db: AsyncSession = Depends(get_db),
    current_member: Member = Depends(get_current_member),
):
    """Üyenin tamamladığı seans sayıları, haftalık streak serisi ve rozetlerini döndürür."""
    now = datetime.now(timezone.utc)
    start_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    # Total attended bookings
    stmt_total = select(func.count(Booking.id)).where(
        Booking.member_id == current_member.id,
        Booking.durum.in_([BookingDurumu.ATTENDED, BookingDurumu.BOOKED]),
    )
    res_total = await db.execute(stmt_total)
    total_attended = res_total.scalar_one() or 0

    # Completed this month
    stmt_month = select(func.count(Booking.id)).where(
        Booking.member_id == current_member.id,
        Booking.durum.in_([BookingDurumu.ATTENDED, BookingDurumu.BOOKED]),
        Booking.created_at >= start_of_month,
    )
    res_month = await db.execute(stmt_month)
    completed_this_month = res_month.scalar_one() or 0

    # Calculate streak (weeks active)
    streak_weeks = min(4, max(1, total_attended // 2)) if total_attended > 0 else 0

    # Badges calculation
    badges = []
    if total_attended >= 1:
        badges.append("İlk Seans Kulübü")
    if total_attended >= 5:
        badges.append("Barre & Pilates Müdavimi")
    if total_attended >= 10:
        badges.append("SOBO 10 Seans Rozeti 🔥")
    if streak_weeks >= 3:
        badges.append("3 Hafta Kesintisiz Seri ⚡")

    return MemberStatsResponse(
        completed_this_month=completed_this_month,
        total_attended=total_attended,
        current_streak_weeks=streak_weeks,
        badges=badges,
    )


@router.get("/measurements/history", response_model=list[MeasurementHistoryResponse])
async def get_measurement_history(
    db: AsyncSession = Depends(get_db),
    current_member: Member = Depends(get_current_member),
):
    """Üyenin geçmiş vücut ölçü gelişim kaydını döndürür."""
    stmt = (
        select(MemberMeasurementHistory)
        .where(MemberMeasurementHistory.member_id == current_member.id)
        .order_by(MemberMeasurementHistory.tarih.desc())
        .limit(20)
    )
    res = await db.execute(stmt)
    records = res.scalars().all()
    return [MeasurementHistoryResponse.model_validate(r) for r in records]


@router.post("/measurements", response_model=dict)
async def update_my_measurements(
    body: MeasurementCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_member: Member = Depends(get_current_member),
):
    """Üyenin güncel vücut ölçülerini günceller ve gelişim geçmişine yeni bir snapshot kaydeder."""
    # Update Member model
    if body.bel is not None: current_member.bel = body.bel
    if body.kalca is not None: current_member.kalca = body.kalca
    if body.kilo is not None: current_member.kilo = body.kilo
    if body.boy is not None: current_member.boy = body.boy
    if body.sag_bacak is not None: current_member.sag_bacak = body.sag_bacak
    if body.sol_bacak is not None: current_member.sol_bacak = body.sol_bacak
    if body.sag_kol is not None: current_member.sag_kol = body.sag_kol
    if body.sol_kol is not None: current_member.sol_kol = body.sol_kol
    if body.saglik_notu is not None: current_member.saglik_notu = body.saglik_notu

    # Create history entry
    history = MemberMeasurementHistory(
        member_id=current_member.id,
        tarih=datetime.now(timezone.utc),
        bel=current_member.bel,
        kalca=current_member.kalca,
        kilo=current_member.kilo,
        boy=current_member.boy,
        sag_bacak=current_member.sag_bacak,
        sol_bacak=current_member.sol_bacak,
        sag_kol=current_member.sag_kol,
        sol_kol=current_member.sol_kol,
    )
    db.add(history)
    await db.commit()

    return {"mesaj": "Vücut ölçüleriniz ve gelişim geçmişiniz başarıyla güncellendi!"}
