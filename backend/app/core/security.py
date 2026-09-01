from datetime import datetime, timedelta, timezone

import jwt

from app.services.hatalar import GecersizOTP, GecersizToken
from app.services.telefon import normalize_telefon
from app.settings import ayarlar

_OTP_STORE: dict[str, str] = {}


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


from app.services.sms import generate_otp_code

def send_otp(telefon: str) -> str:
    """Telefon numarasına OTP doğrulama kodu gönderir."""
    norm_tel = normalize_telefon(telefon)
    kod = generate_otp_code()
    _OTP_STORE[norm_tel] = kod
    return kod


def verify_otp(telefon: str, kod: str) -> bool:
    """OTP doğrulama kodunu kontrol eder."""
    norm_tel = normalize_telefon(telefon)
    stored = _OTP_STORE.get(norm_tel)
    if stored and stored == kod:
        return True

    return False
