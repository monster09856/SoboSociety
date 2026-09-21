from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_member
from app.core.security import create_access_token, send_otp, verify_otp, hash_password, verify_password
from app.models.uyelik import Member
from app.schemas.auth import (
    MemberMeResponse,
    MemberRegisterRequest,
    MemberLoginRequest,
    OTPSendRequest,
    OTPSendResponse,
    OTPVerifyRequest,
    TokenResponse,
    MemberChangePasswordRequest,
)
from app.services.hatalar import GecersizOTP, GecersizTelefon
from app.services.telefon import normalize_telefon
from app.settings import ayarlar

import unicodedata

def normalize_username(s: str) -> str:
    if not s:
        return ""
    # NFKD normalizasyonu ile Türkçe klavye gizli kombinasyon karakterlerini temizle
    s = unicodedata.normalize('NFKD', s)
    s = ''.join(c for c in s if not unicodedata.combining(c))
    return s.strip().lower()


router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register", response_model=TokenResponse)
async def register_endpoint(
    body: MemberRegisterRequest,
    db: AsyncSession = Depends(get_db),
):
    """Yeni üye kaydı oluşturur (Ad Soyad + Kullanıcı Adı + Şifre)."""
    username = normalize_username(body.kullanici_adi)
    if len(username) < 3:
        raise HTTPException(status_code=400, detail="Kullanıcı adı en az 3 karakter olmalıdır.")

    # Kullanıcı adı çakışma kontrolü
    stmt = select(Member).where(Member.kullanici_adi.ilike(username))
    res = await db.execute(stmt)
    existing = res.scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="Bu kullanıcı adı başka bir üye tarafından kullanılıyor.")

    # Telefon zorunlu kontrolü ve formatlama
    if not body.telefon or not body.telefon.strip():
        raise HTTPException(status_code=400, detail="Cep telefonu numarası zorunludur.")

    try:
        norm_tel = normalize_telefon(body.telefon.strip())
    except GecersizTelefon as e:
        raise HTTPException(status_code=400, detail=str(e))

    stmt_tel = select(Member).where(Member.telefon == norm_tel)
    res_tel = await db.execute(stmt_tel)
    existing_tel = res_tel.scalar_one_or_none()
    if existing_tel:
        if existing_tel.sifre_hash:
            raise HTTPException(
                status_code=400,
                detail="Bu telefon numarası ile kayıtlı aktif bir üyelik bulunmaktadır. Lütfen kullanıcı adınız ile giriş yapınız."
            )
        # DM hızlı kayıt ile açılmış ve henüz şifresi oluşturulmamış üye
        existing_tel.kullanici_adi = username
        existing_tel.sifre_hash = hash_password(body.sifre)
        existing_tel.ad = body.ad.strip()
        await db.commit()
        await db.refresh(existing_tel)
        is_admin = norm_tel in ayarlar.admin_telefons or username == "admin"
        if not existing_tel.aktif and not is_admin:
            raise HTTPException(
                status_code=403,
                detail="Üyelik başvurunuz stüdyo yönetimi tarafından incelenmektedir. Hesabınız onaylandığında giriş yapabileceksiniz. ✨",
            )
        token = create_access_token(subject=str(existing_tel.id), is_admin=is_admin)
        return TokenResponse(access_token=token, aktif=True, mesaj="Giriş başarılı")

    is_admin = (norm_tel in ayarlar.admin_telefons) if norm_tel else (username == "admin")
    is_apple_review = (
        ("apple" in username.lower())
        or ("demo" in username.lower())
        or (norm_tel in ["+905550000000", "+905000000000", "+905555555555"])
    )
    # Admin ve Apple review hesapları doğrudan aktif; diğer normal kayıtlar butik stüdyo yönetici onayı bekler
    aktif = is_admin or is_apple_review

    # Yeni üye oluştur
    pw_hash = hash_password(body.sifre)
    new_member = Member(
        ad=body.ad.strip(),
        kullanici_adi=username,
        sifre_hash=pw_hash,
        telefon=norm_tel,
        aktif=aktif,
    )
    db.add(new_member)
    await db.commit()
    await db.refresh(new_member)

    if not aktif:
        try:
            from app.services.bildirim import adminlere_bildirim_gonder
            await adminlere_bildirim_gonder(
                db,
                baslik="✨ Yeni Üyelik Başvurusu!",
                mesaj=f"{new_member.ad} ({new_member.telefon or new_member.kullanici_adi}) stüdyoya kaydoldu, onayınızı bekliyor.",
                tip="YENI_UYE",
            )
            await db.commit()
        except Exception:
            pass
        raise HTTPException(
            status_code=403,
            detail="Üyelik başvurunuz stüdyo yönetimi tarafından incelenmektedir. Hesabınız onaylandığında giriş yapabileceksiniz. ✨",
        )

    token = create_access_token(subject=str(new_member.id), is_admin=is_admin)
    return TokenResponse(access_token=token, aktif=True, mesaj="Giriş başarılı")


@router.post("/login", response_model=TokenResponse)
async def login_endpoint(
    body: MemberLoginRequest,
    db: AsyncSession = Depends(get_db),
):
    """Kullanıcı Adı / Telefon ve Şifre ile giriş yapar."""
    user_input = body.kullanici_adi.strip()
    username = normalize_username(user_input)
    password = body.sifre.strip()

    # GÜVENLİK: Mobil uygulamada test için bırakılmış varsayılan admin girişlerini tamamen engelle
    if (username in ["admin", "05316033080", "+905316033080"]) and (password in ["345678", "admin"]):
        raise HTTPException(
            status_code=400,
            detail="Bu varsayılan giriş devre dışı bırakılmıştır. Lütfen kendi kullanıcı adı ve şifrenizle giriş yapınız veya kayıt olunuz.",
        )

    # Normal Üye Girişi (kullanıcı adı veya telefon ile)
    try:
        norm_tel = normalize_telefon(user_input)
    except Exception:
        norm_tel = None

    if norm_tel:
        stmt = select(Member).where(
            or_(
                Member.kullanici_adi.ilike(username),
                Member.telefon == norm_tel,
            )
        )
    else:
        stmt = select(Member).where(Member.kullanici_adi.ilike(username))
    res = await db.execute(stmt)
    member = res.scalar_one_or_none()

    if not member:
        raise HTTPException(status_code=400, detail="Kullanıcı adı veya şifre hatalı.")

    if not verify_password(password, member.sifre_hash):
        raise HTTPException(status_code=400, detail="Kullanıcı adı veya şifre hatalı.")

    is_admin = (member.telefon in ayarlar.admin_telefons) or (member.kullanici_adi == "admin")

    if not member.aktif and not is_admin:
        raise HTTPException(
            status_code=403,
            detail="Üyelik başvurunuz stüdyo yönetimi tarafından incelenmektedir. Hesabınız onaylandığında giriş yapabileceksiniz. ✨",
        )

    token = create_access_token(subject=str(member.id), is_admin=is_admin)
    return TokenResponse(access_token=token, aktif=True, mesaj="Giriş başarılı")


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

    is_admin = norm_tel in ayarlar.admin_telefons

    if member is None:
        member = Member(
            telefon=norm_tel,
            ad=body.ad if body.ad and body.ad.strip() else "Yeni Üye",
            aktif=is_admin,
        )
        db.add(member)
        await db.commit()
        await db.refresh(member)

    if not member.aktif and not is_admin:
        try:
            from app.services.bildirim import adminlere_bildirim_gonder
            await adminlere_bildirim_gonder(
                db,
                baslik="✨ Yeni Üyelik Başvurusu!",
                mesaj=f"{member.ad} ({member.telefon}) stüdyoya kaydoldu, onayınızı bekliyor.",
                tip="YENI_UYE",
            )
            await db.commit()
        except Exception:
            pass
        raise HTTPException(
            status_code=403,
            detail="Üyelik başvurunuz stüdyo yönetimi tarafından incelenmektedir. Hesabınız onaylandığında giriş yapabileceksiniz. ✨",
        )

    access_token = create_access_token(subject=str(member.id), is_admin=is_admin)
    return TokenResponse(access_token=access_token, token_type="bearer")


from app.schemas.auth import MemberProfileUpdateRequest

@router.get("/me", response_model=MemberMeResponse)
async def get_me_endpoint(
    current_member: Member = Depends(get_current_member),
):
    is_admin = (current_member.telefon in ayarlar.admin_telefons) or (current_member.kullanici_adi == "admin")
    return MemberMeResponse(
        id=current_member.id,
        ad=current_member.ad,
        kullanici_adi=current_member.kullanici_adi,
        telefon=current_member.telefon,
        kvkk_onay_at=current_member.kvkk_onay_at,
        katilimci_gorunurluk_onay=current_member.katilimci_gorunurluk_onay,
        aktif=current_member.aktif,
        is_admin=is_admin,
        bel=current_member.bel,
        kalca=current_member.kalca,
        sag_ic_bacak=current_member.sag_ic_bacak,
        sag_bacak=current_member.sag_bacak,
        sol_ic_bacak=current_member.sol_ic_bacak,
        sol_bacak=current_member.sol_bacak,
        sag_kol=current_member.sag_kol,
        sol_kol=current_member.sol_kol,
        boy=current_member.boy,
        kilo=current_member.kilo,
        saglik_notu=current_member.saglik_notu,
    )


@router.put("/me", response_model=MemberMeResponse)
async def update_me_endpoint(
    body: MemberProfileUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_member: Member = Depends(get_current_member),
):
    """Üye kendi profil bilgilerini ve vücut ölçülerini günceller."""
    fields = [
        "ad", "bel", "kalca", "sag_ic_bacak", "sag_bacak",
        "sol_ic_bacak", "sol_bacak", "sag_kol", "sol_kol",
        "boy", "kilo", "saglik_notu"
    ]
    for f in fields:
        val = getattr(body, f, None)
        if val is not None:
            setattr(current_member, f, val.strip() if isinstance(val, str) else val)

    await db.commit()
    await db.refresh(current_member)

    is_admin = (current_member.telefon in ayarlar.admin_telefons) or (current_member.kullanici_adi == "admin")
    return MemberMeResponse(
        id=current_member.id,
        ad=current_member.ad,
        kullanici_adi=current_member.kullanici_adi,
        telefon=current_member.telefon,
        kvkk_onay_at=current_member.kvkk_onay_at,
        katilimci_gorunurluk_onay=current_member.katilimci_gorunurluk_onay,
        aktif=current_member.aktif,
        is_admin=is_admin,
        bel=current_member.bel,
        kalca=current_member.kalca,
        sag_ic_bacak=current_member.sag_ic_bacak,
        sag_bacak=current_member.sag_bacak,
        sol_ic_bacak=current_member.sol_ic_bacak,
        sol_bacak=current_member.sol_bacak,
        sag_kol=current_member.sag_kol,
        sol_kol=current_member.sol_kol,
        boy=current_member.boy,
        kilo=current_member.kilo,
        saglik_notu=current_member.saglik_notu,
    )


@router.post("/change-password")
async def change_password_endpoint(
    body: MemberChangePasswordRequest,
    db: AsyncSession = Depends(get_db),
    current_member: Member = Depends(get_current_member),
):
    """Giriş yapmış üyenin kendi şifresini değiştirmesini sağlar."""
    if current_member.sifre_hash:
        if not body.mevcut_sifre or not verify_password(body.mevcut_sifre.strip(), current_member.sifre_hash):
            raise HTTPException(status_code=400, detail="Mevcut şifrenizi hatalı girdiniz.")

    new_pw = body.yeni_sifre.strip()
    if len(new_pw) < 4:
        raise HTTPException(status_code=400, detail="Yeni şifre en az 4 karakter olmalıdır.")

    current_member.sifre_hash = hash_password(new_pw)
    await db.commit()
    return {"mesaj": "Şifreniz başarıyla değiştirildi. ✨"}

