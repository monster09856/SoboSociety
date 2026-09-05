from typing import AsyncGenerator

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_access_token
from app.db.session import OturumFabrikasi
from app.models.uyelik import Member
from app.services.hatalar import GecersizToken
from app.settings import ayarlar

security_scheme = HTTPBearer(auto_error=False)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI için veritabanı oturum (AsyncSession) dependency'si."""
    async with OturumFabrikasi() as session:
        yield session


async def get_current_member(
    db: AsyncSession = Depends(get_db),
    credentials: HTTPAuthorizationCredentials | None = Depends(security_scheme),
    token: str | None = None,
) -> Member:
    """Aktif istemci için JWT doğrulaması yapıp mevcut üyeyi (Member) döndürür."""
    raw_token = token or (
        credentials.credentials
        if isinstance(credentials, HTTPAuthorizationCredentials)
        else None
    )
    if not raw_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Yetkilendirme başlığı (Bearer token) eksik",
            headers={"WWW-Authenticate": "Bearer"},
        )

    try:
        payload = decode_access_token(raw_token)
    except GecersizToken as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        ) from e

    sub = payload.get("sub")
    if not sub:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Geçersiz token (sub eksik)",
        )

    member: Member | None = None
    if str(sub).isdigit():
        member = await db.get(Member, int(sub))

    if member is None:
        stmt = select(Member).where(Member.telefon == str(sub))
        res = await db.execute(stmt)
        member = res.scalar_one_or_none()

    if member is None or not member.aktif:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Üye bulunamadı veya hesabı aktif değil",
        )

    return member


async def get_optional_current_member(
    db: AsyncSession = Depends(get_db),
    credentials: HTTPAuthorizationCredentials | None = Depends(security_scheme),
    token: str | None = None,
) -> Member | None:
    """İsteğe bağlı üye doğrulaması. Token varsa üyeyi döner, yoksa veya geçersizse None döner."""
    try:
        return await get_current_member(db=db, credentials=credentials, token=token)
    except HTTPException:
        return None


async def get_current_admin(
    db: AsyncSession = Depends(get_db),
    current_member: Member = Depends(get_current_member),
    credentials: HTTPAuthorizationCredentials | None = Depends(security_scheme),
    token: str | None = None,
) -> Member:
    """Mevcut üyenin yönetici (admin) yetkisine sahip olduğunu doğrular."""
    raw_token = token or (
        credentials.credentials
        if isinstance(credentials, HTTPAuthorizationCredentials)
        else None
    )
    is_admin_claim = False
    if raw_token:
        try:
            payload = decode_access_token(raw_token)
            is_admin_claim = bool(payload.get("is_admin", False))
        except GecersizToken:
            pass

    is_admin_phone = current_member.telefon in ayarlar.admin_telefons

    if not (is_admin_claim or is_admin_phone):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bu işlem için admin yetkisi gerekiyor",
        )

    return current_member
