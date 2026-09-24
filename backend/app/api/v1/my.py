from datetime import date, datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_member, get_db
from app.models.kredi import CreditLedger, MemberPackage, Package
from app.models.rezervasyon import Booking, BookingDurumu
from app.models.uyelik import Member, MemberMeasurementHistory
from app.schemas.member import (
    MeasurementCreateRequest,
    MeasurementHistoryResponse,
    MemberPackageSummary,
    MemberStatsResponse,
    MemberSummaryResponse,
)
from app.services.kredi import bakiye, bakiye_detay

router = APIRouter(prefix="/my", tags=["my"])


@router.get("/summary", response_model=MemberSummaryResponse)
async def get_my_summary(
    db: AsyncSession = Depends(get_db),
    current_member: Member = Depends(get_current_member),
):
    """Giriş yapmış üyenin bakiye, paket ve rezervasyon özetini döndürür."""
    kredi_bakiye, grup_bakiye, bireysel_bakiye = await bakiye_detay(db, current_member.id)
    now = datetime.now(timezone.utc)
    today = date.today()

    # Paket bilgilerini çek
    mp_res = await db.execute(
        select(MemberPackage, Package)
        .join(Package, MemberPackage.package_id == Package.id)
        .where(MemberPackage.member_id == current_member.id)
        .order_by(MemberPackage.id.desc())
    )
    mp_rows = mp_res.all()

    aktif_pkg_ad = None
    pkg_bitis_str = None
    kalan_gun = None
    toplam_ders = None
    paket_listesi: list[MemberPackageSummary] = []

    for mp, p in mp_rows:
        pkg_name = getattr(mp, "ozel_paket_adi", None) or (p.ad if p else "Stüdyo Ders Paketi")
        ders_sayisi = getattr(mp, "ders_adedi", p.ders_adedi if p else 0)
        baslangic_str = mp.baslangic.strftime("%d.%m.%Y") if mp.baslangic else ""
        bitis_str = mp.bitis.strftime("%d.%m.%Y") if mp.bitis else ""
        days_left = (mp.bitis - today).days if mp.bitis else 0
        is_active = (mp.baslangic <= today < mp.bitis) if (mp.baslangic and mp.bitis) else False
        is_b = any(k in pkg_name.lower() for k in ["bireysel", "özel", "birebir", "1-on-1"])

        l_res = await db.execute(
            select(func.coalesce(func.sum(CreditLedger.miktar), 0))
            .where(CreditLedger.member_package_id == mp.id)
        )
        mp_rem = max(0, int(l_res.scalar_one() or 0))

        paket_listesi.append(
            MemberPackageSummary(
                id=mp.id,
                ad=pkg_name,
                baslangic_tarihi=baslangic_str,
                bitis_tarihi=bitis_str,
                kalan_gun=max(0, days_left),
                toplam_ders=ders_sayisi,
                kalan_ders=mp_rem,
                kategori="Bireysel" if is_b else "Grup",
                aktif=is_active,
            )
        )
    active_pkgs = [p for p in paket_listesi if p.aktif]
    if len(active_pkgs) == 1:
        aktif_pkg_ad = active_pkgs[0].ad
        pkg_bitis_str = active_pkgs[0].bitis_tarihi
        kalan_gun = active_pkgs[0].kalan_gun
        toplam_ders = active_pkgs[0].toplam_ders
    elif len(active_pkgs) > 1:
        aktif_pkg_ad = " + ".join([p.ad for p in active_pkgs])
        latest_pkg = max(active_pkgs, key=lambda p: p.kalan_gun)
        pkg_bitis_str = latest_pkg.bitis_tarihi
        kalan_gun = latest_pkg.kalan_gun
        toplam_ders = sum(p.toplam_ders for p in active_pkgs)
    elif mp_rows:
        mp, p = mp_rows[0]
        aktif_pkg_ad = getattr(mp, "ozel_paket_adi", None) or (p.ad if p else "Stüdyo Ders Paketi")
        pkg_bitis_str = mp.bitis.strftime("%d.%m.%Y") if mp.bitis else ""
        kalan_gun = max(0, (mp.bitis - today).days) if mp.bitis else 0
        toplam_ders = getattr(mp, "ders_adedi", p.ders_adedi if p else 0)

    from sqlalchemy.orm import selectinload
    from app.models.program import ClassSession

    stmt = (
        select(Booking)
        .options(
            selectinload(Booking.session).selectinload(ClassSession.class_type),
            selectinload(Booking.session).selectinload(ClassSession.instructor),
            selectinload(Booking.session).selectinload(ClassSession.room),
        )
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
        grup_bakiye=grup_bakiye,
        bireysel_bakiye=bireysel_bakiye,
        aktif_paket_adi=aktif_pkg_ad,
        paket_bitis_tarihi=pkg_bitis_str,
        kalan_gun_sayisi=kalan_gun,
        toplam_ders_adedi=toplam_ders,
        sabit_ders_saatleri=current_member.sabit_ders_saatleri,
        borc_bakiye=float(current_member.borc_bakiye or 0.0),
        paketler=paket_listesi,
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
    if body.sag_ic_bacak is not None: current_member.sag_ic_bacak = body.sag_ic_bacak
    if body.sol_ic_bacak is not None: current_member.sol_ic_bacak = body.sol_ic_bacak
    if body.sag_kol is not None: current_member.sag_kol = body.sag_kol
    if body.sol_kol is not None: current_member.sol_kol = body.sol_kol
    if body.saglik_notu is not None: current_member.saglik_notu = body.saglik_notu

    # Create history entry
    measurement_date = body.tarih or datetime.now(timezone.utc)
    history = MemberMeasurementHistory(
        member_id=current_member.id,
        tarih=measurement_date,
        bel=current_member.bel,
        kalca=current_member.kalca,
        kilo=current_member.kilo,
        boy=current_member.boy,
        sag_bacak=current_member.sag_bacak,
        sol_bacak=current_member.sol_bacak,
        sag_ic_bacak=current_member.sag_ic_bacak,
        sol_ic_bacak=current_member.sol_ic_bacak,
        sag_kol=current_member.sag_kol,
        sol_kol=current_member.sol_kol,
        notlar=body.notlar,
    )
    db.add(history)

    from app.services.bildirim import adminlere_bildirim_gonder
    await adminlere_bildirim_gonder(
        db,
        baslik="📏 Üye Form / Ölçü Güncellemesi",
        mesaj=f"{current_member.ad} üyesi vücut ölçülerini ve form bilgilerini güncelledi.",
        tip="UYE_GUNCELLEME",
    )

    await db.commit()

    return {"mesaj": "Vücut ölçüleriniz ve gelişim geçmişiniz başarıyla güncellendi!"}
