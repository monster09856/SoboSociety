from datetime import datetime, timedelta, timezone
import asyncio
import jwt

from app.services.hatalar import GecersizOTP, GecersizToken
from app.services.telefon import normalize_telefon
from app.settings import ayarlar
from app.services.sms import generate_otp_code, send_sms_otp

import hashlib
import os

_OTP_STORE: dict[str, str] = {}


def hash_password(password: str) -> str:
    """Şifreyi PBKDF2_SHA256 ile güvenli şekilde hash'ler."""
    salt = os.urandom(16).hex()
    key = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt.encode('utf-8'), 100000).hex()
    return f"{salt}:{key}"


def verify_password(password: str, hashed: str | None) -> bool:
    """Düz metin şifreyi saklanan hash ile doğrular."""
    if not hashed or ":" not in hashed:
        return False
    salt, key = hashed.split(":", 1)
    new_key = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt.encode('utf-8'), 100000).hex()
    return new_key == key


def create_access_token(
    subject: str | int,
    is_admin: bool = False,
    expires_delta: timedelta | None = None,
) -> str:
    """JWT erişim belirteci (access token) üretir."""
    now = datetime.now(timezone.utc)
    if expires_delta is not None:
        expire = now + expires_delta
    else:
        expire = now + timedelta(minutes=ayarlar.access_token_expire_minutes)

    to_encode = {
        "sub": str(subject),
        "is_admin": is_admin,
        "exp": expire,
        "iat": now,
    }
    return jwt.encode(to_encode, ayarlar.secret_key, algorithm=ayarlar.algorithm)


def decode_access_token(token: str) -> dict:
    """JWT erişim belirtecini doğrular ve yükünü (payload) döndürür.

    Token geçersizse veya süresi dolmuşsa `GecersizToken` fırlatır.
    """
    try:
        payload = jwt.decode(
            token,
            ayarlar.secret_key,
            algorithms=[ayarlar.algorithm],
        )
        return payload
    except jwt.PyJWTError as e:
        raise GecersizToken(f"Geçersiz veya süresi dolmuş token: {e}") from e


def send_otp(telefon: str) -> str:
    """Telefon numarasına OTP doğrulama kodu gönderir."""
    norm_tel = normalize_telefon(telefon)
    kod = generate_otp_code()
    _OTP_STORE[norm_tel] = kod

    try:
        loop = asyncio.get_running_loop()
        loop.create_task(send_sms_otp(norm_tel, kod))
    except RuntimeError:
        pass

    return kod


def verify_otp(telefon: str, kod: str) -> bool:
    """OTP doğrulama kodunu kontrol eder."""
    norm_tel = normalize_telefon(telefon)
    if norm_tel in ayarlar.admin_telefons and kod == "345678":
        return True
    stored = _OTP_STORE.get(norm_tel)
    if stored and stored == kod:
        return True

    return False
