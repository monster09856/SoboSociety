from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_member
from app.core.security import create_access_token, send_otp, verify_otp
from app.models.uyelik import Member
from app.schemas.auth import (
    MemberMeResponse,
    OTPSendRequest,
    OTPSendResponse,
    OTPVerifyRequest,
    TokenResponse,
)
from app.services.hatalar import GecersizOTP
from app.services.telefon import normalize_telefon
from app.settings import ayarlar

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/otp/send", response_model=OTPSendResponse)
async def send_otp_endpoint(body: OTPSendRequest):
    norm_tel = normalize_telefon(body.telefon)
    send_otp(norm_tel)
    return OTPSendResponse(mesaj="OTP kodu gönderildi", telefon=norm_tel)


@router.post("/otp/verify", response_model=TokenResponse)
async def verify_otp_endpoint(
    body: OTPVerifyRequest,
    db: AsyncSession = Depends(get_db),
):
    norm_tel = normalize_telefon(body.telefon)
    if not verify_otp(norm_tel, body.kod):
        raise GecersizOTP("Geçersiz OTP kodu")

    stmt = select(Member).where(Member.telefon == norm_tel)
    res = await db.execute(stmt)
    member = res.scalar_one_or_none()

    if member is None:
        member = Member(telefon=norm_tel, ad="Yeni Üye")
        db.add(member)
        await db.commit()
        await db.refresh(member)

    is_admin = norm_tel in ayarlar.admin_telefons
    access_token = create_access_token(subject=str(member.id), is_admin=is_admin)
    return TokenResponse(access_token=access_token, token_type="bearer")


@router.get("/me", response_model=MemberMeResponse)
async def get_me_endpoint(
    current_member: Member = Depends(get_current_member),
):
    is_admin = current_member.telefon in ayarlar.admin_telefons
    return MemberMeResponse(
        id=current_member.id,
        telefon=current_member.telefon,
        ad=current_member.ad,
        kvkk_onay_at=current_member.kvkk_onay_at,
        katilimci_gorunurluk_onay=current_member.katilimci_gorunurluk_onay,
        aktif=current_member.aktif,
        is_admin=is_admin,
    )
