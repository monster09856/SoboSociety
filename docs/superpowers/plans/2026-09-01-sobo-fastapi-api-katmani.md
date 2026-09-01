# Sobo FastAPI HTTP API Katmanı Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Faz 1'de tamamlanan domain çekirdeğini FastAPI HTTP katmanı ile dış dünyaya açmak — Auth (SMS OTP + JWT), Üye rezervasyon API'leri, Admin/Eğitmen Hızlı İşlem API'leri ve CORS konfigürasyonu.

**Architecture:** FastAPI Router'ları (`app/api/`), Pydantic Schemas (`app/schemas/`), Security (`app/core/security.py`), DB Dependency Injection (`app/api/deps.py`), Main App (`app/main.py`). Domain hataları (`SoboHata`) FastAPI exception handler ile 4xx HTTP yanıtlarına dönüştürülür.

**Tech Stack:** FastAPI · Pydantic v2 · PyJWT · SQLAlchemy 2.0 (async Session) · pytest + httpx (AsyncClient)

---

## Global Constraints

- **Tüm domain kuralları `app/services/` katmanına delege edilir.** Router'lar iş mantığı içermez, sadece HTTP DTO dönüşümleri, yetkilendirme ve servis çağrılarını yaparlar.
- **Tüm `datetime` yanıtları ISO-8601 formatında UTC'dir.**
- **Auth:** Telefon + SMS OTP. Geliştirme/test ortamında sabit OTP (`123456`) kabul edilir.
- **Hata Yönetimi:** Domain istisnaları (`SoboHata` türevleri) global exception handler ile 400 Bad Request, 404 Not Found, 409 Conflict vb. standart JSON formatında döner.

---

## Dosya Yapısı

```
sobo/
└── backend/
    ├── app/
    │   ├── core/
    │   │   ├── __init__.py
    │   │   └── security.py           JWT token üretme/doğrulama & OTP mock/servis
    │   ├── schemas/
    │   │   ├── __init__.py
    │   │   ├── auth.py               OTP ve Token şemaları
    │   │   ├── member.py             Üye ve rezervasyon DTO'ları
    │   │   └── admin.py              Admin hızlı işlem DTO'ları
    │   ├── api/
    │   │   ├── __init__.py
    │   │   ├── deps.py               get_db, get_current_member, get_current_admin
    │   │   └── v1/
    │   │       ├── __init__.py
    │   │       ├── router.py         Tüm v1 router'larını birleştirir
    │   │       ├── auth.py           /auth/otp/send, /auth/otp/verify, /auth/me
    │   │       ├── sessions.py       /sessions (Ders listesi)
    │   │       ├── bookings.py       /bookings (Rezerve & İptal & Bekleme)
    │   │       ├── my.py             /my/summary, /my/bookings, /my/packages
    │   │       └── admin.py          /admin/today, /admin/quick-booking, /admin/attendance
    │   └── main.py                   FastAPI app instance, CORS, Exception handlers
    └── tests/
        ├── test_api_auth.py
        ├── test_api_member.py
        ├── test_api_admin.py
        └── test_api_e2e.py
```

---

### Task 1: Auth & Güvenlik Altyapısı (JWT, OTP, Dependencies)

**Files:**
- Create: `backend/app/core/__init__.py`
- Create: `backend/app/core/security.py`
- Create: `backend/app/schemas/__init__.py`
- Create: `backend/app/schemas/auth.py`
- Create: `backend/app/api/__init__.py`
- Create: `backend/app/api/deps.py`
- Create: `backend/app/api/v1/__init__.py`
- Create: `backend/app/api/v1/auth.py`
- Create: `backend/tests/test_api_auth.py`

**Interfaces:**
- `app.core.security.create_access_token(subject: str, is_admin: bool = False) -> str`
- `app.core.security.decode_access_token(token: str) -> dict`
- `app.core.security.verify_otp(telefon: str, kod: str) -> bool`
- `app.api.deps.get_current_member(db, token)` -> `Member`
- `app.api.deps.get_current_admin(db, current_member)` -> `Member` (is_admin=True)

- [ ] **Step 1: Test dosyasını yaz (`backend/tests/test_api_auth.py`)**
- [ ] **Step 2: Security & OTP modülünü yaz (`backend/app/core/security.py`)**
- [ ] **Step 3: Auth Schemas oluştur (`backend/app/schemas/auth.py`)**
- [ ] **Step 4: Auth dependencies ve router oluştur (`backend/app/api/deps.py` ve `backend/app/api/v1/auth.py`)**
- [ ] **Step 5: FastAPI App & Main Route (`backend/app/main.py`)**
- [ ] **Step 6: Run tests and verify auth passes**

---

### Task 2: Üye Akışı API'leri (Ders Listeleme, Rezervasyon, İptal, Bekleme Listesi)

**Files:**
- Create: `backend/app/schemas/member.py`
- Create: `backend/app/api/v1/sessions.py`
- Create: `backend/app/api/v1/bookings.py`
- Create: `backend/app/api/v1/my.py`
- Create: `backend/tests/test_api_member.py`

- [ ] **Step 1: Member Schemas oluştur (`backend/app/schemas/member.py`)**
- [ ] **Step 2: Session Listeleme Endpoints (`backend/app/api/v1/sessions.py`)**
- [ ] **Step 3: Rezervasyon & İptal & Bekleme Endpoints (`backend/app/api/v1/bookings.py`)**
- [ ] **Step 4: Üyeliğim & Bakiye Özet API (`backend/app/api/v1/my.py`)**
- [ ] **Step 5: Router'ları birleştir (`backend/app/api/v1/router.py`) ve Main App'e ekle**
- [ ] **Step 6: Member API testlerini çalıştır**

---

### Task 3: Admin Paneli API'leri (Bugün, Hızlı Kayıt, Yoklama, Paket Tanımlama)

**Files:**
- Create: `backend/app/schemas/admin.py`
- Create: `backend/app/api/v1/admin.py`
- Create: `backend/tests/test_api_admin.py`

- [ ] **Step 1: Admin Schemas oluştur (`backend/app/schemas/admin.py`)**
- [ ] **Step 2: Admin Endpoints (`backend/app/api/v1/admin.py`)**
- [ ] **Step 3: Test dosyasını yaz ve doğrula (`backend/tests/test_api_admin.py`)**

---

### Task 4: E2E Integration Testing & Polish

- [ ] **Step 1: E2E test senaryosunu oluştur (`backend/tests/test_api_e2e.py`)**
- [ ] **Step 2: Tüm API ve Domain testlerini çalıştır**
