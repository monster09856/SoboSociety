# Sobo Backend Çekirdeği Implementasyon Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rezervasyon sisteminin domain çekirdeğini kurmak — veri modeli, kredi ledger'ı, kontenjan yarışına dayanıklı rezervasyon, iptal penceresi, bekleme listesi ve yoklama. Hepsi testlerle.

**Architecture:** Katmanlı: `models/` (SQLAlchemy 2.0 `Mapped[]`), `services/` (iş kuralları, saf ve test edilebilir), `db/` (oturum yönetimi). Bu fazda **HTTP katmanı yok** — servisler doğrudan test edilir. FastAPI router'ları Faz 2'de admin paneliyle birlikte gelir, çünkü endpoint tasarımı panelin ihtiyacına göre şekillenmeli.

**Tech Stack:** Python 3.12 · FastAPI · SQLAlchemy 2.0 (async, asyncpg) · Alembic · Pydantic v2 · PostgreSQL 16 · pytest + pytest-asyncio

**Spec:** `docs/superpowers/specs/2026-08-25-sobo-society-design.md`

## Global Constraints

- **Zaman:** Tüm `datetime` değerleri **UTC** ve **timezone-aware** saklanır (`DateTime(timezone=True)`). Sunum katmanı `Europe/Istanbul`'a çevirir. Servis fonksiyonları asla `datetime.now()` çağırmaz — `now` parametre olarak geçilir, böylece testler zamanı kontrol eder.
- **Dil:** Domain terimleri ve yorumlar Türkçe (AkorLab konvansiyonu). Sınıf adları İngilizce (`Member`, `Booking`), alan adları Türkçe (`telefon`, `dolu_sayi`).
- **Kredi:** `member_packages` üzerinde kalan-ders sayacı **YOKTUR**. Bakiye her zaman `SUM(credit_ledger.miktar)`.
- **Ledger append-only:** `credit_ledger` satırları asla UPDATE veya DELETE edilmez. Düzeltme yeni satırla yapılır (`admin_adjust`).
- **Redis Faz 1'de yok.** Spec §5.2(c) Redis'ten söz ediyor ama bekleme listesi teklif süresi `waitlist_entries.teklif_bitis` sütunuyla çözülüyor. İkinci bir altyapı bileşeni eklemek için gerçek bir sebep yok (YAGNI).
- **İptal sınırı kullanıcı lehinedir:** `now <= son_iptal_ani` ise iptal penceredeki iptaldir. Tam sınırda iptal hakkı vardır.
- **Migration:** Her model değişikliği Alembic migration'ı ile gelir. `alembic upgrade head` boş bir veritabanında hatasız çalışmalıdır.

---

## Dosya Yapısı

```
sobo/
├── backend/
│   ├── pyproject.toml
│   ├── alembic.ini
│   ├── docker-compose.yml          postgres:16 (test + dev)
│   ├── alembic/
│   │   ├── env.py
│   │   └── versions/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── settings.py             Pydantic Settings — DATABASE_URL
│   │   ├── db/
│   │   │   ├── __init__.py
│   │   │   └── session.py          engine, AsyncSessionLocal, get_db
│   │   ├── models/
│   │   │   ├── __init__.py         tüm modelleri re-export (Alembic autogenerate için)
│   │   │   ├── base.py             Base, ZamanDamgali mixin
│   │   │   ├── uyelik.py           Member, Instructor
│   │   │   ├── program.py          ClassType, Room, ScheduleTemplate, ClassSession
│   │   │   ├── rezervasyon.py      Booking, WaitlistEntry
│   │   │   └── kredi.py            Package, MemberPackage, CreditLedger, LedgerTipi
│   │   └── services/
│   │       ├── __init__.py
│   │       ├── hatalar.py          domain istisnaları — tek yerde
│   │       ├── telefon.py          normalize_telefon()
│   │       ├── program_uretimi.py  şablondan ders oturumu üretme
│   │       ├── kredi.py            bakiye(), hareket_ekle()
│   │       ├── rezervasyon.py      rezerve_et(), iptal_et()
│   │       ├── bekleme.py          siraya_gir(), sirayi_ilerlet()
│   │       └── yoklama.py          yoklama_al()
│   └── tests/
│       ├── conftest.py             DB fixture'ları
│       ├── test_telefon.py
│       ├── test_modeller.py
│       ├── test_program_uretimi.py
│       ├── test_kredi.py
│       ├── test_rezervasyon.py
│       ├── test_iptal.py
│       ├── test_bekleme.py
│       └── test_yoklama.py
```

**Neden `models/` dosyaları katmana göre değil konuya göre bölündü:** birlikte değişen şeyler birlikte durur. `ClassSession` ile `ScheduleTemplate` her zaman birlikte değişir; `Booking` ile `WaitlistEntry` de öyle. Tek bir `models.py` 400 satırı geçerdi.

---

### Task 1: Proje iskeleti ve test altyapısı

**Files:**
- Create: `backend/pyproject.toml`
- Create: `backend/docker-compose.yml`
- Create: `backend/app/__init__.py`, `backend/app/settings.py`
- Create: `backend/app/db/__init__.py`, `backend/app/db/session.py`
- Create: `backend/app/models/__init__.py`, `backend/app/models/base.py`
- Create: `backend/tests/conftest.py`, `backend/tests/test_altyapi.py`

**Interfaces:**
- Consumes: —
- Produces:
  - `app.models.base.Base` — DeclarativeBase
  - `app.models.base.ZamanDamgali` — `created_at`, `updated_at` mixin
  - `app.db.session.motor` — AsyncEngine
  - `app.db.session.OturumFabrikasi` — `async_sessionmaker[AsyncSession]`
  - conftest fixture'ları: `db` (rollback izolasyonlu), `temiz_db` (gerçek commit, eşzamanlılık testleri için)

- [ ] **Step 1: pyproject.toml oluştur**

```toml
[project]
name = "sobo-backend"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.115",
    "sqlalchemy[asyncio]>=2.0.36",
    "asyncpg>=0.30",
    "alembic>=1.14",
    "pydantic>=2.10",
    "pydantic-settings>=2.7",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.3",
    "pytest-asyncio>=0.25",
]

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]

[tool.setuptools.packages.find]
include = ["app*"]
```

- [ ] **Step 2: docker-compose.yml oluştur**

```yaml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_USER: sobo
      POSTGRES_PASSWORD: sobo
      POSTGRES_DB: sobo
    ports:
      - "5433:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U sobo"]
      interval: 2s
      timeout: 3s
      retries: 15
```

Port 5433 seçildi — 5432 makinede başka bir Postgres tarafından kullanılıyor olabilir.

- [ ] **Step 3: settings.py ve db/session.py oluştur**

```python
# app/settings.py
from pydantic_settings import BaseSettings, SettingsConfigDict


class Ayarlar(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+asyncpg://sobo:sobo@localhost:5433/sobo"


ayarlar = Ayarlar()
```

```python
# app/db/session.py
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.settings import ayarlar

motor = create_async_engine(ayarlar.database_url, pool_pre_ping=True)

OturumFabrikasi = async_sessionmaker(
    motor,
    class_=AsyncSession,
    expire_on_commit=False,
)
```

`expire_on_commit=False`: commit sonrası nesne alanlarına erişim yeni bir sorgu tetiklemesin — async'te bu beklenmedik lazy-load hatalarına yol açar.

- [ ] **Step 4: models/base.py oluştur**

```python
# app/models/base.py
from datetime import datetime

from sqlalchemy import DateTime, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class ZamanDamgali:
    """Oluşturma ve güncelleme zamanı taşıyan tablolar için mixin."""

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
```

```python
# app/models/__init__.py
from app.models.base import Base, ZamanDamgali

__all__ = ["Base", "ZamanDamgali"]
```

- [ ] **Step 5: conftest.py oluştur**

İki farklı fixture var ve **farkları kritik**:

- `db` — her test bir transaction içinde çalışır, sonunda rollback. Hızlı, izole. Testlerin çoğu bunu kullanır.
- `temiz_db` — gerçek commit yapar, sonunda tabloları TRUNCATE eder. **Yalnız eşzamanlılık testleri** bunu kullanır, çünkü iki ayrı bağlantının birbirinin satır kilidini görmesi gerekir; rollback fixture'ında iki bağlantı aynı transaction'ı paylaşamaz.

```python
# tests/conftest.py
import asyncio

import pytest
import pytest_asyncio
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.models import Base
from app.settings import ayarlar

TEST_URL = ayarlar.database_url


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="session")
async def motor():
    m = create_async_engine(TEST_URL, pool_pre_ping=True)
    async with m.begin() as baglanti:
        await baglanti.run_sync(Base.metadata.drop_all)
        await baglanti.run_sync(Base.metadata.create_all)
    yield m
    await m.dispose()


@pytest_asyncio.fixture
async def db(motor):
    """Transaction içinde izole oturum — test sonunda rollback."""
    baglanti = await motor.connect()
    islem = await baglanti.begin()
    oturum = AsyncSession(bind=baglanti, expire_on_commit=False)
    yield oturum
    await oturum.close()
    await islem.rollback()
    await baglanti.close()


@pytest_asyncio.fixture
async def temiz_db(motor):
    """Gerçek commit yapan fabrika — eşzamanlılık testleri için.

    Rollback izolasyonu burada kullanılamaz: iki ayrı bağlantının
    birbirinin satır kilidini görmesi gerekiyor.
    """
    fabrika = async_sessionmaker(motor, class_=AsyncSession, expire_on_commit=False)
    yield fabrika
    tablolar = ", ".join(t.name for t in reversed(Base.metadata.sorted_tables))
    async with motor.begin() as baglanti:
        await baglanti.execute(text(f"TRUNCATE {tablolar} RESTART IDENTITY CASCADE"))
```

- [ ] **Step 6: Altyapı testini yaz**

```python
# tests/test_altyapi.py
from sqlalchemy import text


async def test_veritabani_baglantisi_calisiyor(db):
    sonuc = await db.execute(text("SELECT 1"))
    assert sonuc.scalar_one() == 1
```

- [ ] **Step 7: Testi çalıştır**

```bash
cd backend
docker compose up -d db
pip install -e ".[dev]"
pytest tests/test_altyapi.py -v
```

Beklenen: PASS.

- [ ] **Step 8: Alembic'i başlat**

```bash
cd backend
alembic init -t async alembic
```

`alembic/env.py` içinde `target_metadata` satırını değiştir:

```python
from app.models import Base
target_metadata = Base.metadata
```

Ve `alembic.ini` içindeki `sqlalchemy.url` satırını sil; `env.py`'ye ekle:

```python
from app.settings import ayarlar
config.set_main_option("sqlalchemy.url", ayarlar.database_url)
```

- [ ] **Step 9: Commit**

```bash
git add backend/
git commit -m "feat(backend): proje iskeleti, async DB oturumu ve test altyapısı

İki test fixture'ı: rollback izolasyonlu 'db' (varsayılan) ve gerçek
commit yapan 'temiz_db' (eşzamanlılık testleri için — iki bağlantının
birbirinin satır kilidini görmesi gerekiyor)."
```

---

### Task 2: Üyelik modelleri ve telefon normalizasyonu

**Files:**
- Create: `backend/app/models/uyelik.py`
- Create: `backend/app/services/telefon.py`
- Create: `backend/app/services/hatalar.py`
- Modify: `backend/app/models/__init__.py`
- Create: `backend/tests/test_telefon.py`, `backend/tests/test_modeller.py`

**Interfaces:**
- Consumes: `Base`, `ZamanDamgali` (Task 1)
- Produces:
  - `app.services.telefon.normalize_telefon(ham: str) -> str` — `+90XXXXXXXXXX` döner
  - `app.services.hatalar.GecersizTelefon(SoboHata)`
  - `app.models.uyelik.Member` — `id, telefon, ad, kvkk_onay_at, katilimci_gorunurluk_onay, aktif`
  - `app.models.uyelik.Instructor` — `id, ad, biyografi, foto_url, aktif`

**Neden telefon normalizasyonu ayrı bir servis:** Üye kaydı üç ayrı yerden geliyor — üye kendi kaydolur, eğitmen panelden açar, DM'den gelen telefonu elle girer. "0531 603 30 80", "+90 531 603 30 80" ve "531 603 30 80" aynı kişidir. Normalize edilmezse aynı üye için üç kayıt oluşur ve kredi bakiyesi bölünür.

- [ ] **Step 1: Telefon testini yaz (başarısız olacak)**

```python
# tests/test_telefon.py
import pytest

from app.services.hatalar import GecersizTelefon
from app.services.telefon import normalize_telefon


@pytest.mark.parametrize(
    "ham",
    [
        "0531 603 30 80",
        "+90 531 603 30 80",
        "531 603 30 80",
        "05316033080",
        "+905316033080",
        "90 531 603 30 80",
        "(0531) 603-30-80",
    ],
)
def test_ayni_numaranin_tum_yazimlari_ayni_sonuca_gider(ham):
    assert normalize_telefon(ham) == "+905316033080"


@pytest.mark.parametrize(
    "ham",
    [
        "",
        "123",
        "0531 603 30 8",       # bir hane eksik
        "0531 603 30 800",     # bir hane fazla
        "abc",
        "+1 555 123 4567",     # Türkiye dışı
        "0231 603 30 80",      # cep numarası 5 ile başlamalı
    ],
)
def test_gecersiz_numaralar_reddedilir(ham):
    with pytest.raises(GecersizTelefon):
        normalize_telefon(ham)
```

- [ ] **Step 2: Testi çalıştır, başarısız olduğunu gör**

Run: `pytest tests/test_telefon.py -v`
Beklenen: FAIL — `ModuleNotFoundError: No module named 'app.services.telefon'`

- [ ] **Step 3: hatalar.py ve telefon.py yaz**

```python
# app/services/hatalar.py
class SoboHata(Exception):
    """Tüm domain hatalarının kökü. API katmanı bunu yakalayıp 4xx'e çevirir."""


class GecersizTelefon(SoboHata):
    pass
```

```python
# app/services/telefon.py
import re

from app.services.hatalar import GecersizTelefon

_RAKAM_DISI = re.compile(r"\D")


def normalize_telefon(ham: str) -> str:
    """Türkiye cep numarasını `+90XXXXXXXXXX` biçimine getirir.

    Üye kaydı üç ayrı yerden geliyor (üye kendi, eğitmen paneli, DM'den elle
    giriş). Normalize edilmezse aynı kişi için birden çok kayıt oluşur ve
    kredi bakiyesi bölünür — bu yüzden telefon tek doğrulama noktasıdır.
    """
    if not ham:
        raise GecersizTelefon("Telefon numarası boş")

    rakamlar = _RAKAM_DISI.sub("", ham)

    # Ülke kodu ve baştaki sıfırı ayıkla, geriye 10 hane kalmalı: 5XXXXXXXXX
    if rakamlar.startswith("90"):
        rakamlar = rakamlar[2:]
    elif rakamlar.startswith("0"):
        rakamlar = rakamlar[1:]

    if len(rakamlar) != 10 or not rakamlar.startswith("5"):
        raise GecersizTelefon(f"Geçerli bir Türkiye cep numarası değil: {ham}")

    return f"+90{rakamlar}"
```

- [ ] **Step 4: Testi çalıştır**

Run: `pytest tests/test_telefon.py -v`
Beklenen: 14 PASS.

- [ ] **Step 5: Üyelik modellerini yaz**

```python
# app/models/uyelik.py
from datetime import datetime

from sqlalchemy import Boolean, DateTime, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, ZamanDamgali


class Member(ZamanDamgali, Base):
    """Stüdyo üyesi. Kimlik anahtarı telefon numarasıdır — e-posta yok.

    Eğitmen üyeyi panelden telefonla açar; üye uygulamaya/web'e girip aynı
    numarayı doğrulayınca kayıt kendiliğinden eşleşir. Instagram DM'den
    sisteme geçişi mümkün kılan mekanizma budur.
    """

    __tablename__ = "members"

    id: Mapped[int] = mapped_column(primary_key=True)
    telefon: Mapped[str] = mapped_column(String(16), unique=True, index=True)
    ad: Mapped[str] = mapped_column(String(120))

    # KVKK aydınlatma onayı — zaman damgası kanıttır, boolean yeterli değil
    kvkk_onay_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), default=None
    )
    # Ders katılımcı listesinde adının görünmesine rıza. AYRI ve varsayılan KAPALI.
    katilimci_gorunurluk_onay: Mapped[bool] = mapped_column(Boolean, default=False)

    aktif: Mapped[bool] = mapped_column(Boolean, default=True)


class Instructor(ZamanDamgali, Base):
    __tablename__ = "instructors"

    id: Mapped[int] = mapped_column(primary_key=True)
    ad: Mapped[str] = mapped_column(String(120))
    biyografi: Mapped[str | None] = mapped_column(Text, default=None)
    foto_url: Mapped[str | None] = mapped_column(String(500), default=None)
    aktif: Mapped[bool] = mapped_column(Boolean, default=True)
```

```python
# app/models/__init__.py
from app.models.base import Base, ZamanDamgali
from app.models.uyelik import Instructor, Member

__all__ = ["Base", "ZamanDamgali", "Member", "Instructor"]
```

- [ ] **Step 6: Model testini yaz**

```python
# tests/test_modeller.py
import pytest
from sqlalchemy.exc import IntegrityError

from app.models import Member


async def test_uye_kaydedilir_ve_varsayilanlar_dogru(db):
    uye = Member(telefon="+905316033080", ad="Selin")
    db.add(uye)
    await db.flush()

    assert uye.id is not None
    assert uye.aktif is True
    # Katılımcı görünürlüğü rızası varsayılan olarak KAPALI olmalı
    assert uye.katilimci_gorunurluk_onay is False
    assert uye.kvkk_onay_at is None


async def test_ayni_telefon_iki_kez_kaydedilemez(db):
    db.add(Member(telefon="+905316033080", ad="Selin"))
    await db.flush()

    db.add(Member(telefon="+905316033080", ad="Selin Y."))
    with pytest.raises(IntegrityError):
        await db.flush()
```

- [ ] **Step 7: Testleri çalıştır**

Run: `pytest tests/ -v`
Beklenen: hepsi PASS.

- [ ] **Step 8: Migration üret ve uygula**

```bash
cd backend
alembic revision --autogenerate -m "uyelik: members ve instructors"
alembic upgrade head
```

Üretilen dosyayı **aç ve oku** — autogenerate her zaman doğru çıkarım yapmaz. `members.telefon` üzerinde unique index olduğunu doğrula.

- [ ] **Step 9: Commit**

```bash
git add backend/
git commit -m "feat(backend): üyelik modelleri ve telefon normalizasyonu

Telefon tek kimlik anahtarı. Üç ayrı giriş noktası (üye, panel, DM'den elle)
aynı numarayı farklı yazıyor; normalize edilmezse kredi bakiyesi bölünür."
```

---

### Task 3: Program modelleri — ders tipi, salon, şablon, oturum

**Files:**
- Create: `backend/app/models/program.py`
- Modify: `backend/app/models/__init__.py`
- Modify: `backend/tests/test_modeller.py`

**Interfaces:**
- Consumes: `Base`, `ZamanDamgali`, `Instructor` (Task 1-2)
- Produces:
  - `ClassType` — `id, ad, kontenjan, sure_dk, renk, iptal_penceresi_saat, aktif`
  - `Room` — `id, ad, aktif`
  - `ScheduleTemplate` — `id, hafta_gunu (0=Pzt..6=Paz), saat_dk (gün başından dakika), class_type_id, instructor_id, room_id, gecerli_baslangic, gecerli_bitis`
  - `ClassSession` — `id, baslangic, class_type_id, instructor_id, room_id, kontenjan, dolu_sayi, durum, template_id`
  - `SessionDurumu` — `AKTIF = "active"`, `IPTAL = "cancelled"`

- [ ] **Step 1: Program modellerini yaz**

```python
# app/models/program.py
from datetime import date, datetime
from enum import StrEnum

from sqlalchemy import (
    Boolean, CheckConstraint, Date, DateTime, ForeignKey,
    Integer, String, UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, ZamanDamgali


class SessionDurumu(StrEnum):
    AKTIF = "active"
    IPTAL = "cancelled"


class ClassType(ZamanDamgali, Base):
    """Ders tipi: Barre, Pilates, Functional, Birebir."""

    __tablename__ = "class_types"

    id: Mapped[int] = mapped_column(primary_key=True)
    ad: Mapped[str] = mapped_column(String(80), unique=True)
    kontenjan: Mapped[int] = mapped_column(Integer)
    sure_dk: Mapped[int] = mapped_column(Integer)
    renk: Mapped[str] = mapped_column(String(9), default="#A2846F")
    iptal_penceresi_saat: Mapped[int] = mapped_column(Integer, default=6)
    aktif: Mapped[bool] = mapped_column(Boolean, default=True)

    __table_args__ = (
        CheckConstraint("kontenjan > 0", name="ck_class_type_kontenjan"),
        CheckConstraint("sure_dk > 0", name="ck_class_type_sure"),
    )


class Room(ZamanDamgali, Base):
    """Salon. v1'de tek kayıt var ama model çoklu salonu destekliyor —
    ikinci salon açıldığında şema değişmesin."""

    __tablename__ = "rooms"

    id: Mapped[int] = mapped_column(primary_key=True)
    ad: Mapped[str] = mapped_column(String(80), unique=True)
    aktif: Mapped[bool] = mapped_column(Boolean, default=True)


class ScheduleTemplate(ZamanDamgali, Base):
    """Haftalık tekrar eden program satırı: "her Salı 19:00 Barre".

    Somut ders oturumları buradan üretilir (Task 4). Şablon değişince geçmiş
    oturumlar etkilenmez.
    """

    __tablename__ = "schedule_templates"

    id: Mapped[int] = mapped_column(primary_key=True)
    hafta_gunu: Mapped[int] = mapped_column(Integer)  # 0=Pazartesi .. 6=Pazar
    saat_dk: Mapped[int] = mapped_column(Integer)     # gün başından dakika (19:00 -> 1140)

    class_type_id: Mapped[int] = mapped_column(ForeignKey("class_types.id"))
    instructor_id: Mapped[int] = mapped_column(ForeignKey("instructors.id"))
    room_id: Mapped[int] = mapped_column(ForeignKey("rooms.id"))

    gecerli_baslangic: Mapped[date] = mapped_column(Date)
    gecerli_bitis: Mapped[date | None] = mapped_column(Date, default=None)

    __table_args__ = (
        CheckConstraint("hafta_gunu BETWEEN 0 AND 6", name="ck_template_gun"),
        CheckConstraint("saat_dk BETWEEN 0 AND 1439", name="ck_template_saat"),
    )


class ClassSession(ZamanDamgali, Base):
    """Somut ders oturumu — belirli bir tarih ve saatteki ders."""

    __tablename__ = "class_sessions"

    id: Mapped[int] = mapped_column(primary_key=True)
    baslangic: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)

    class_type_id: Mapped[int] = mapped_column(ForeignKey("class_types.id"))
    instructor_id: Mapped[int] = mapped_column(ForeignKey("instructors.id"))
    room_id: Mapped[int] = mapped_column(ForeignKey("rooms.id"))

    # Kontenjan, class_types.kontenjan'ın KOPYASIDIR — referansı değil.
    # Ders tipinin kontenjanı 8'den 6'ya düşerse geçmiş oturumların kaydı
    # bozulmamalı. Ayrıca tek bir dersin kontenjanı istisnaen değişebilir
    # (iki reformer arızalandı). Snapshot bu yüzden.
    kontenjan: Mapped[int] = mapped_column(Integer)
    dolu_sayi: Mapped[int] = mapped_column(Integer, default=0)

    durum: Mapped[str] = mapped_column(String(16), default=SessionDurumu.AKTIF)
    template_id: Mapped[int | None] = mapped_column(
        ForeignKey("schedule_templates.id"), default=None
    )

    __table_args__ = (
        # Aynı salonda aynı anda iki ders olamaz. Bu kısıt aynı zamanda
        # şablon üretiminin idempotent olmasını da garanti eder (Task 4).
        UniqueConstraint("room_id", "baslangic", name="uq_salon_saat"),
        CheckConstraint(
            "dolu_sayi >= 0 AND dolu_sayi <= kontenjan", name="ck_session_dolu_sayi"
        ),
    )
```

- [ ] **Step 2: __init__.py güncelle**

```python
# app/models/__init__.py
from app.models.base import Base, ZamanDamgali
from app.models.program import (
    ClassSession, ClassType, Room, ScheduleTemplate, SessionDurumu,
)
from app.models.uyelik import Instructor, Member

__all__ = [
    "Base", "ZamanDamgali",
    "Member", "Instructor",
    "ClassType", "Room", "ScheduleTemplate", "ClassSession", "SessionDurumu",
]
```

- [ ] **Step 3: Kısıt testlerini yaz**

```python
# tests/test_modeller.py — dosyanın sonuna ekle
from datetime import UTC, datetime

from app.models import ClassSession, ClassType, Instructor, Room


async def _program_kur(db, *, kontenjan: int = 8):
    tip = ClassType(ad="Barre", kontenjan=kontenjan, sure_dk=50)
    egitmen = Instructor(ad="Deniz")
    salon = Room(ad="Stüdyo")
    db.add_all([tip, egitmen, salon])
    await db.flush()
    return tip, egitmen, salon


async def test_ayni_salonda_ayni_anda_iki_ders_olamaz(db):
    tip, egitmen, salon = await _program_kur(db)
    an = datetime(2026, 9, 1, 16, 0, tzinfo=UTC)

    db.add(ClassSession(
        baslangic=an, class_type_id=tip.id, instructor_id=egitmen.id,
        room_id=salon.id, kontenjan=8,
    ))
    await db.flush()

    db.add(ClassSession(
        baslangic=an, class_type_id=tip.id, instructor_id=egitmen.id,
        room_id=salon.id, kontenjan=8,
    ))
    with pytest.raises(IntegrityError):
        await db.flush()


async def test_dolu_sayi_kontenjani_asamaz(db):
    tip, egitmen, salon = await _program_kur(db, kontenjan=2)

    db.add(ClassSession(
        baslangic=datetime(2026, 9, 1, 16, 0, tzinfo=UTC),
        class_type_id=tip.id, instructor_id=egitmen.id,
        room_id=salon.id, kontenjan=2, dolu_sayi=3,
    ))
    with pytest.raises(IntegrityError):
        await db.flush()


async def test_kontenjan_snapshot_ders_tipinden_bagimsiz(db):
    """Ders tipinin kontenjanı düşse bile açılmış oturumun kontenjanı sabit kalır."""
    tip, egitmen, salon = await _program_kur(db, kontenjan=8)
    oturum = ClassSession(
        baslangic=datetime(2026, 9, 1, 16, 0, tzinfo=UTC),
        class_type_id=tip.id, instructor_id=egitmen.id,
        room_id=salon.id, kontenjan=tip.kontenjan,
    )
    db.add(oturum)
    await db.flush()

    tip.kontenjan = 6
    await db.flush()
    await db.refresh(oturum)

    assert oturum.kontenjan == 8
```

- [ ] **Step 4: Testleri çalıştır**

Run: `pytest tests/test_modeller.py -v`
Beklenen: hepsi PASS.

- [ ] **Step 5: Migration üret ve uygula**

```bash
cd backend
alembic revision --autogenerate -m "program: ders tipi, salon, sablon, oturum"
alembic upgrade head
```

Üretilen dosyayı aç: `uq_salon_saat` ve `ck_session_dolu_sayi` kısıtlarının migration'a girdiğini doğrula. Autogenerate CheckConstraint'leri bazen atlar — eksikse elle ekle.

- [ ] **Step 6: Commit**

```bash
git add backend/
git commit -m "feat(backend): program modelleri — tip, salon, şablon, oturum

class_sessions.kontenjan bilinçli olarak class_types.kontenjan'ın kopyası:
ders tipinin kontenjanı değişince geçmiş oturumlar bozulmamalı.
uq_salon_saat kısıtı hem çakışan dersi hem de çift üretimi engelliyor."
```

---

### Task 4: Şablondan ders oturumu üretme

**Files:**
- Create: `backend/app/services/program_uretimi.py`
- Create: `backend/tests/test_program_uretimi.py`

**Interfaces:**
- Consumes: `ScheduleTemplate`, `ClassSession`, `ClassType` (Task 3)
- Produces:
  - `app.services.program_uretimi.STUDYO_TZ` — `ZoneInfo("Europe/Istanbul")`
  - `app.services.program_uretimi.uret(db, *, baslangic: date, bitis: date) -> int` — üretilen yeni oturum sayısını döner, idempotent

**Neden idempotent olması şart:** Bu fonksiyon haftalık bir zamanlanmış görevden çağrılacak. Görev iki kez tetiklenirse (yeniden deneme, elle çalıştırma, deploy sırasında çakışma) her ders iki kez açılmamalı. `uq_salon_saat` kısıtı + `ON CONFLICT DO NOTHING` bunu veritabanı seviyesinde garanti eder — uygulama kodunda "önce var mı diye bak" kontrolü yarış koşuluna açıktır.

**Neden saat `saat_dk` olarak tutuluyor:** Şablon "her Salı 19:00" der; bu **yerel** bir saattir. Tarihe uygulanıp `Europe/Istanbul`'da yorumlanır, sonra UTC'ye çevrilir. Şablonda UTC saklamak yanlış olurdu — ülke saat dilimi kuralını değiştirirse (Türkiye 2016'da yaptı) tüm şablonlar bozulurdu.

- [ ] **Step 1: Testi yaz (başarısız olacak)**

```python
# tests/test_program_uretimi.py
from datetime import UTC, date, datetime

from sqlalchemy import func, select

from app.models import ClassSession, ClassType, Instructor, Room, ScheduleTemplate
from app.services.program_uretimi import uret


async def _sablon_kur(db, *, hafta_gunu: int, saat_dk: int, gecerli_bitis: date | None = None):
    tip = ClassType(ad="Barre", kontenjan=8, sure_dk=50)
    egitmen = Instructor(ad="Deniz")
    salon = Room(ad="Stüdyo")
    db.add_all([tip, egitmen, salon])
    await db.flush()

    sablon = ScheduleTemplate(
        hafta_gunu=hafta_gunu,
        saat_dk=saat_dk,
        class_type_id=tip.id,
        instructor_id=egitmen.id,
        room_id=salon.id,
        gecerli_baslangic=date(2026, 9, 1),
        gecerli_bitis=gecerli_bitis,
    )
    db.add(sablon)
    await db.flush()
    return sablon


async def _oturumlar(db) -> list[ClassSession]:
    sonuc = await db.execute(select(ClassSession).order_by(ClassSession.baslangic))
    return list(sonuc.scalars())


async def test_haftalik_sablon_dogru_gunlerde_oturum_uretir(db):
    # 1 Eylül 2026 Salı. hafta_gunu=1 -> Salı
    await _sablon_kur(db, hafta_gunu=1, saat_dk=19 * 60)

    sayi = await uret(db, baslangic=date(2026, 9, 1), bitis=date(2026, 9, 21))

    assert sayi == 3
    tarihler = [o.baslangic.astimezone(UTC).date() for o in await _oturumlar(db)]
    assert tarihler == [date(2026, 9, 1), date(2026, 9, 8), date(2026, 9, 15)]


async def test_yerel_saat_utc_ye_cevrilir(db):
    """Şablon 19:00 yerel saat der; Europe/Istanbul UTC+3, yani 16:00 UTC."""
    await _sablon_kur(db, hafta_gunu=1, saat_dk=19 * 60)

    await uret(db, baslangic=date(2026, 9, 1), bitis=date(2026, 9, 2))

    oturum = (await _oturumlar(db))[0]
    assert oturum.baslangic.astimezone(UTC) == datetime(2026, 9, 1, 16, 0, tzinfo=UTC)


async def test_iki_kez_calistirmak_cift_oturum_uretmez(db):
    await _sablon_kur(db, hafta_gunu=1, saat_dk=19 * 60)

    ilk = await uret(db, baslangic=date(2026, 9, 1), bitis=date(2026, 9, 21))
    ikinci = await uret(db, baslangic=date(2026, 9, 1), bitis=date(2026, 9, 21))

    assert ilk == 3
    assert ikinci == 0

    toplam = await db.execute(select(func.count()).select_from(ClassSession))
    assert toplam.scalar_one() == 3


async def test_gecerlilik_bitisinden_sonra_uretilmez(db):
    await _sablon_kur(
        db, hafta_gunu=1, saat_dk=19 * 60, gecerli_bitis=date(2026, 9, 8)
    )

    sayi = await uret(db, baslangic=date(2026, 9, 1), bitis=date(2026, 9, 21))

    assert sayi == 2  # 1 ve 8 Eylül; 15 Eylül geçerlilik dışında


async def test_kontenjan_ders_tipinden_kopyalanir(db):
    await _sablon_kur(db, hafta_gunu=1, saat_dk=19 * 60)

    await uret(db, baslangic=date(2026, 9, 1), bitis=date(2026, 9, 2))

    oturum = (await _oturumlar(db))[0]
    assert oturum.kontenjan == 8
    assert oturum.dolu_sayi == 0
```

- [ ] **Step 2: Testi çalıştır, başarısız olduğunu gör**

Run: `pytest tests/test_program_uretimi.py -v`
Beklenen: FAIL — `ModuleNotFoundError: No module named 'app.services.program_uretimi'`

- [ ] **Step 3: program_uretimi.py yaz**

```python
# app/services/program_uretimi.py
from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import ClassSession, ClassType, ScheduleTemplate

STUDYO_TZ = ZoneInfo("Europe/Istanbul")


def _yerel_ani_utc_ye_cevir(gun: date, saat_dk: int) -> datetime:
    """Şablondaki yerel saati o güne uygulayıp UTC'ye çevirir.

    Şablon "her Salı 19:00" der ve bu YEREL bir saattir. UTC saklamak yanlış
    olurdu: ülke saat dilimi kuralını değiştirirse (Türkiye 2016'da yaptı)
    tüm şablonlar sessizce kayardı.
    """
    yerel = datetime.combine(gun, time(hour=saat_dk // 60, minute=saat_dk % 60))
    return yerel.replace(tzinfo=STUDYO_TZ).astimezone(ZoneInfo("UTC"))


async def uret(db: AsyncSession, *, baslangic: date, bitis: date) -> int:
    """`baslangic` ve `bitis` (dahil) arasındaki günler için oturum üretir.

    İdempotenttir: aynı aralık için iki kez çağrılırsa ikincisi 0 döner.
    Garanti veritabanından gelir (`uq_salon_saat` + ON CONFLICT DO NOTHING),
    uygulama kodundaki "önce var mı" kontrolünden değil — o kontrol yarış
    koşuluna açıktır.
    """
    sonuc = await db.execute(
        select(ScheduleTemplate, ClassType.kontenjan)
        .join(ClassType, ClassType.id == ScheduleTemplate.class_type_id)
        .where(ClassType.aktif.is_(True))
    )
    sablonlar = sonuc.all()
    if not sablonlar:
        return 0

    satirlar: list[dict] = []
    gun = baslangic
    while gun <= bitis:
        for sablon, kontenjan in sablonlar:
            if sablon.hafta_gunu != gun.weekday():
                continue
            if gun < sablon.gecerli_baslangic:
                continue
            if sablon.gecerli_bitis is not None and gun > sablon.gecerli_bitis:
                continue

            satirlar.append({
                "baslangic": _yerel_ani_utc_ye_cevir(gun, sablon.saat_dk),
                "class_type_id": sablon.class_type_id,
                "instructor_id": sablon.instructor_id,
                "room_id": sablon.room_id,
                "kontenjan": kontenjan,
                "dolu_sayi": 0,
                "template_id": sablon.id,
            })
        gun += timedelta(days=1)

    if not satirlar:
        return 0

    stmt = (
        insert(ClassSession)
        .values(satirlar)
        .on_conflict_do_nothing(constraint="uq_salon_saat")
        .returning(ClassSession.id)
    )
    eklenen = await db.execute(stmt)
    await db.flush()
    return len(eklenen.scalars().all())
```

- [ ] **Step 4: Testleri çalıştır**

Run: `pytest tests/test_program_uretimi.py -v`
Beklenen: 5 PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/
git commit -m "feat(backend): şablondan ders oturumu üretme

İdempotent: garanti uq_salon_saat + ON CONFLICT DO NOTHING'den geliyor,
uygulama kodundaki 'önce var mı' kontrolünden değil.

Şablon yerel saat tutar, UTC'ye üretim anında çevrilir — ülke saat dilimi
kuralını değiştirirse şablonlar kaymasın."
```

---

### Task 5: Kredi modelleri — paket ve ledger

**Files:**
- Create: `backend/app/models/kredi.py`
- Modify: `backend/app/models/__init__.py`

**Interfaces:**
- Consumes: `Base`, `ZamanDamgali`, `Member` (Task 1-2)
- Produces:
  - `LedgerTipi` — StrEnum: `PURCHASE, BOOKING, CANCEL_REFUND, LATE_CANCEL, NO_SHOW, EXPIRE, ADMIN_ADJUST`
  - `Package` — `id, ad, ders_adedi, gecerlilik_gun, fiyat_kurus, aktif`
  - `MemberPackage` — `id, member_id, package_id, baslangic, bitis`
  - `CreditLedger` — `id, member_id, member_package_id, tip, miktar, sebep, booking_id, created_at`

- [ ] **Step 1: Kredi modellerini yaz**

```python
# app/models/kredi.py
from datetime import date, datetime
from enum import StrEnum

from sqlalchemy import (
    Boolean, CheckConstraint, Date, DateTime, ForeignKey,
    Integer, String, func,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, ZamanDamgali


class LedgerTipi(StrEnum):
    """Kredi hareketi tipleri.

    LATE_CANCEL ve NO_SHOW miktarı 0'dır ama satır yine de yazılır: bakiyeyi
    değiştirmezler, NEYİN NEDEN YANDIĞINI anlatırlar. "Benim 3 dersim daha
    vardı" tartışması küçük stüdyoda her ay çıkar ve sayaçla değil, tarihçeyle
    kapanır.
    """

    PURCHASE = "purchase"
    BOOKING = "booking"
    CANCEL_REFUND = "cancel_refund"
    LATE_CANCEL = "late_cancel"
    NO_SHOW = "no_show"
    EXPIRE = "expire"
    ADMIN_ADJUST = "admin_adjust"


class Package(ZamanDamgali, Base):
    __tablename__ = "packages"

    id: Mapped[int] = mapped_column(primary_key=True)
    ad: Mapped[str] = mapped_column(String(80))
    ders_adedi: Mapped[int] = mapped_column(Integer)
    gecerlilik_gun: Mapped[int] = mapped_column(Integer)
    # Fiyat kuruş cinsinden tam sayı — para asla float tutulmaz
    fiyat_kurus: Mapped[int] = mapped_column(Integer)
    aktif: Mapped[bool] = mapped_column(Boolean, default=True)

    __table_args__ = (
        CheckConstraint("ders_adedi > 0", name="ck_package_ders_adedi"),
        CheckConstraint("gecerlilik_gun > 0", name="ck_package_gecerlilik"),
    )


class MemberPackage(ZamanDamgali, Base):
    """Üyeye tanımlanmış paket. Kalan ders sayacı YOKTUR — bakiye ledger'dan
    hesaplanır."""

    __tablename__ = "member_packages"

    id: Mapped[int] = mapped_column(primary_key=True)
    member_id: Mapped[int] = mapped_column(ForeignKey("members.id"), index=True)
    package_id: Mapped[int] = mapped_column(ForeignKey("packages.id"))
    baslangic: Mapped[date] = mapped_column(Date)
    bitis: Mapped[date] = mapped_column(Date)


class CreditLedger(Base):
    """Append-only kredi hareket defteri.

    Bu tablodaki satırlar ASLA UPDATE veya DELETE edilmez. Düzeltme yeni bir
    ADMIN_ADJUST satırıyla yapılır. `updated_at` bilerek yoktur — güncellenen
    bir satır kavramı bu tabloda yanlış olurdu.
    """

    __tablename__ = "credit_ledger"

    id: Mapped[int] = mapped_column(primary_key=True)
    member_id: Mapped[int] = mapped_column(ForeignKey("members.id"), index=True)
    member_package_id: Mapped[int | None] = mapped_column(
        ForeignKey("member_packages.id"), default=None
    )
    tip: Mapped[str] = mapped_column(String(24))
    miktar: Mapped[int] = mapped_column(Integer)
    sebep: Mapped[str] = mapped_column(String(200))
    booking_id: Mapped[int | None] = mapped_column(Integer, default=None, index=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
```

`booking_id` bilerek ForeignKey **değil**: `bookings` tablosu Task 7'de geliyor ve ledger ondan önce var olabilmeli. Ayrıca bir rezervasyon kaydı silinse bile (ki silinmeyecek) ledger izi kalmalı.

- [ ] **Step 2: __init__.py güncelle**

```python
# app/models/__init__.py
from app.models.base import Base, ZamanDamgali
from app.models.kredi import CreditLedger, LedgerTipi, MemberPackage, Package
from app.models.program import (
    ClassSession, ClassType, Room, ScheduleTemplate, SessionDurumu,
)
from app.models.uyelik import Instructor, Member

__all__ = [
    "Base", "ZamanDamgali",
    "Member", "Instructor",
    "ClassType", "Room", "ScheduleTemplate", "ClassSession", "SessionDurumu",
    "Package", "MemberPackage", "CreditLedger", "LedgerTipi",
]
```

- [ ] **Step 3: Migration üret ve uygula**

```bash
cd backend
alembic revision --autogenerate -m "kredi: paket ve ledger"
alembic upgrade head
```

- [ ] **Step 4: Testleri çalıştır (regresyon kontrolü)**

Run: `pytest tests/ -v`
Beklenen: mevcut testlerin hepsi hâlâ PASS.

- [ ] **Step 5: Commit**

```bash
git add backend/
git commit -m "feat(backend): paket ve append-only kredi ledger modelleri

member_packages üzerinde kalan-ders sayacı yok; bakiye SUM(ledger.miktar).
LATE_CANCEL ve NO_SHOW satırları 0 miktarla yazılır — bakiyeyi değiştirmez,
neyin neden yandığını anlatır."
```

---

### Task 6: Kredi servisi

**Files:**
- Create: `backend/app/services/kredi.py`
- Create: `backend/tests/test_kredi.py`
- Modify: `backend/app/services/hatalar.py`

**Interfaces:**
- Consumes: `CreditLedger`, `LedgerTipi`, `MemberPackage`, `Package` (Task 5)
- Produces:
  - `bakiye(db, member_id: int) -> int`
  - `hareket_ekle(db, *, member_id, tip: LedgerTipi, miktar: int, sebep: str, member_package_id=None, booking_id=None) -> CreditLedger`
  - `paket_tanimla(db, *, member_id, package_id, baslangic: date) -> MemberPackage` — paketi açar ve PURCHASE satırını yazar
  - `app.services.hatalar.YetersizKredi(SoboHata)`

- [ ] **Step 1: Testi yaz (başarısız olacak)**

```python
# tests/test_kredi.py
from datetime import date

from app.models import LedgerTipi, Member, Package
from app.services.kredi import bakiye, hareket_ekle, paket_tanimla


async def _uye_ve_paket(db):
    uye = Member(telefon="+905316033080", ad="Selin")
    paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
    db.add_all([uye, paket])
    await db.flush()
    return uye, paket


async def test_hareketi_olmayan_uyenin_bakiyesi_sifir(db):
    uye, _ = await _uye_ve_paket(db)
    assert await bakiye(db, uye.id) == 0


async def test_paket_tanimlamak_bakiyeyi_ders_adedi_kadar_artirir(db):
    uye, paket = await _uye_ve_paket(db)

    uye_paketi = await paket_tanimla(
        db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1)
    )

    assert await bakiye(db, uye.id) == 8
    assert uye_paketi.bitis == date(2026, 10, 31)  # 1 Eylül + 60 gün


async def test_rezervasyon_ve_iade_bakiyede_dengelenir(db):
    uye, paket = await _uye_ve_paket(db)
    await paket_tanimla(db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1))

    await hareket_ekle(db, member_id=uye.id, tip=LedgerTipi.BOOKING, miktar=-1, sebep="Barre 09:30")
    assert await bakiye(db, uye.id) == 7

    await hareket_ekle(db, member_id=uye.id, tip=LedgerTipi.CANCEL_REFUND, miktar=1, sebep="Pencerede iptal")
    assert await bakiye(db, uye.id) == 8


async def test_gec_iptal_bakiyeyi_degistirmez_ama_iz_birakir(db):
    uye, paket = await _uye_ve_paket(db)
    await paket_tanimla(db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1))
    await hareket_ekle(db, member_id=uye.id, tip=LedgerTipi.BOOKING, miktar=-1, sebep="Barre 09:30")

    kayit = await hareket_ekle(
        db, member_id=uye.id, tip=LedgerTipi.LATE_CANCEL, miktar=0,
        sebep="Ders saatine 2 saat kala iptal",
    )

    assert await bakiye(db, uye.id) == 7  # kredi yandı, geri gelmedi
    assert kayit.tip == LedgerTipi.LATE_CANCEL
    assert kayit.miktar == 0


async def test_admin_duzeltmesi_bakiyeyi_degistirir(db):
    uye, paket = await _uye_ve_paket(db)
    await paket_tanimla(db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1))

    await hareket_ekle(
        db, member_id=uye.id, tip=LedgerTipi.ADMIN_ADJUST, miktar=2,
        sebep="Eğitmen hastalandı, iki ders iade edildi",
    )

    assert await bakiye(db, uye.id) == 10


async def test_bakiye_baska_uyenin_hareketlerini_saymaz(db):
    uye, paket = await _uye_ve_paket(db)
    await paket_tanimla(db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1))

    baskasi = Member(telefon="+905321112233", ad="Ece")
    db.add(baskasi)
    await db.flush()

    assert await bakiye(db, baskasi.id) == 0
```

- [ ] **Step 2: Testi çalıştır, başarısız olduğunu gör**

Run: `pytest tests/test_kredi.py -v`
Beklenen: FAIL — `ModuleNotFoundError: No module named 'app.services.kredi'`

- [ ] **Step 3: hatalar.py'ye YetersizKredi ekle**

```python
# app/services/hatalar.py — dosyanın sonuna ekle
class YetersizKredi(SoboHata):
    pass
```

- [ ] **Step 4: kredi.py yaz**

```python
# app/services/kredi.py
from datetime import date, timedelta

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import CreditLedger, LedgerTipi, MemberPackage, Package


async def bakiye(db: AsyncSession, member_id: int) -> int:
    """Üyenin kalan ders kredisi.

    Her zaman ledger'dan hesaplanır, hiçbir yerde sayaç tutulmaz. Sayaç ile
    tarihçe ayrışabilir; ayrıştığında hangisinin doğru olduğunu kimse bilemez.
    """
    sonuc = await db.execute(
        select(func.coalesce(func.sum(CreditLedger.miktar), 0)).where(
            CreditLedger.member_id == member_id
        )
    )
    return int(sonuc.scalar_one())


async def hareket_ekle(
    db: AsyncSession,
    *,
    member_id: int,
    tip: LedgerTipi,
    miktar: int,
    sebep: str,
    member_package_id: int | None = None,
    booking_id: int | None = None,
) -> CreditLedger:
    """Ledger'a bir satır yazar. Satırlar asla güncellenmez veya silinmez."""
    kayit = CreditLedger(
        member_id=member_id,
        member_package_id=member_package_id,
        tip=tip,
        miktar=miktar,
        sebep=sebep,
        booking_id=booking_id,
    )
    db.add(kayit)
    await db.flush()
    return kayit


async def paket_tanimla(
    db: AsyncSession, *, member_id: int, package_id: int, baslangic: date
) -> MemberPackage:
    """Üyeye paket açar ve karşılığında PURCHASE satırını yazar.

    İkisi tek işlemde olmalı: paket açılıp kredi yazılmazsa üye parasını
    ödemiş ama ders hakkı görünmeyen bir hesapla kalır.
    """
    paket = await db.get(Package, package_id)
    if paket is None:
        raise ValueError(f"Paket bulunamadı: {package_id}")

    uye_paketi = MemberPackage(
        member_id=member_id,
        package_id=package_id,
        baslangic=baslangic,
        bitis=baslangic + timedelta(days=paket.gecerlilik_gun),
    )
    db.add(uye_paketi)
    await db.flush()

    await hareket_ekle(
        db,
        member_id=member_id,
        tip=LedgerTipi.PURCHASE,
        miktar=paket.ders_adedi,
        sebep=f"{paket.ad} paketi tanımlandı",
        member_package_id=uye_paketi.id,
    )
    return uye_paketi
```

- [ ] **Step 5: Testleri çalıştır**

Run: `pytest tests/test_kredi.py -v`
Beklenen: 6 PASS.

- [ ] **Step 6: Commit**

```bash
git add backend/
git commit -m "feat(backend): kredi servisi — bakiye, hareket, paket tanımlama

Bakiye her zaman SUM(ledger.miktar); hiçbir yerde sayaç yok. Sayaç ile
tarihçe ayrıştığında hangisinin doğru olduğu bilinemez."
```

---

### Task 7: Rezervasyon ve kontenjan yarışı

**Files:**
- Create: `backend/app/models/rezervasyon.py`
- Create: `backend/app/services/rezervasyon.py`
- Modify: `backend/app/models/__init__.py`, `backend/app/services/hatalar.py`
- Create: `backend/tests/test_rezervasyon.py`

**Interfaces:**
- Consumes: `ClassSession`, `SessionDurumu` (Task 3), `bakiye`, `hareket_ekle`, `LedgerTipi` (Task 5-6)
- Produces:
  - `BookingDurumu` — StrEnum: `BOOKED, CANCELLED, ATTENDED, NO_SHOW`
  - `BookingKaynagi` — StrEnum: `APP, WEB, ADMIN`
  - `Booking` — `id, member_id, session_id, durum, kaynak, cancelled_at`
  - `rezerve_et(db, *, member_id, session_id, kaynak=BookingKaynagi.APP) -> Booking`
  - Hatalar: `DersDolu`, `DersIptalEdilmis`, `ZatenRezerve`, `YetersizKredi`

**Bu görevin kalbi — kontenjan yarışı:**

İki üye son yere aynı anda basarsa ne olur? Kilit almak yerine tek atomik UPDATE kullanılıyor:

```sql
UPDATE class_sessions SET dolu_sayi = dolu_sayi + 1
 WHERE id = :id AND dolu_sayi < kontenjan AND durum = 'active'
RETURNING dolu_sayi;
```

Etkilenen satır 0 ise ders dolmuştur. Neden bu doğru çalışır: PostgreSQL READ COMMITTED izolasyonunda ikinci UPDATE birincinin satır kilidini bekler; birinci commit edince ikinci **WHERE koşulunu yeniden değerlendirir** (EvalPlanQual). Yani `dolu_sayi < kontenjan` güncel değerle sınanır ve son yer iki kez satılmaz.

`SELECT ... FOR UPDATE` de çalışırdı ama iki round-trip ve deadlock riski getirir. Uygulama tarafında "önce say, sonra ekle" **çalışmaz** — iki istek de aynı sayıyı okur.

- [ ] **Step 1: Rezervasyon modelini yaz**

```python
# app/models/rezervasyon.py
from datetime import datetime
from enum import StrEnum

from sqlalchemy import DateTime, ForeignKey, Index, Integer, String, text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, ZamanDamgali


class BookingDurumu(StrEnum):
    BOOKED = "booked"
    CANCELLED = "cancelled"
    ATTENDED = "attended"
    NO_SHOW = "no_show"


class BookingKaynagi(StrEnum):
    APP = "app"
    WEB = "web"
    ADMIN = "admin"


class Booking(ZamanDamgali, Base):
    __tablename__ = "bookings"

    id: Mapped[int] = mapped_column(primary_key=True)
    member_id: Mapped[int] = mapped_column(ForeignKey("members.id"), index=True)
    session_id: Mapped[int] = mapped_column(ForeignKey("class_sessions.id"), index=True)

    durum: Mapped[str] = mapped_column(String(16), default=BookingDurumu.BOOKED)
    kaynak: Mapped[str] = mapped_column(String(8), default=BookingKaynagi.APP)
    cancelled_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), default=None
    )

    __table_args__ = (
        # Kısmi unique index: bir üye aynı derse aynı anda yalnız BİR aktif
        # rezervasyon yapabilir. Tam unique olsaydı iptal edip yeniden
        # rezerve etmek imkânsız olurdu.
        Index(
            "uq_aktif_rezervasyon",
            "member_id",
            "session_id",
            unique=True,
            postgresql_where=text("durum = 'booked'"),
        ),
    )


class WaitlistEntry(ZamanDamgali, Base):
    """Dolu derse sıraya giren üye. Sıra numarası girilme anına göre artar."""

    __tablename__ = "waitlist_entries"

    id: Mapped[int] = mapped_column(primary_key=True)
    member_id: Mapped[int] = mapped_column(ForeignKey("members.id"), index=True)
    session_id: Mapped[int] = mapped_column(ForeignKey("class_sessions.id"), index=True)
    sira: Mapped[int] = mapped_column(Integer)
    # Yer açıldığında bu üyeye teklif edildi; bu ana kadar cevap vermezse sıra ilerler
    teklif_bitis: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), default=None
    )
    kullanildi: Mapped[bool] = mapped_column(default=False)

    __table_args__ = (
        Index("uq_bekleme", "member_id", "session_id", unique=True),
    )
```

- [ ] **Step 2: __init__.py ve hatalar.py güncelle**

```python
# app/models/__init__.py — import ve __all__ satırlarına ekle
from app.models.rezervasyon import Booking, BookingDurumu, BookingKaynagi, WaitlistEntry
```

`__all__` listesine ekle: `"Booking", "BookingDurumu", "BookingKaynagi", "WaitlistEntry"`

```python
# app/services/hatalar.py — dosyanın sonuna ekle
class DersDolu(SoboHata):
    pass


class DersIptalEdilmis(SoboHata):
    pass


class ZatenRezerve(SoboHata):
    pass
```

- [ ] **Step 3: Testleri yaz (başarısız olacak)**

```python
# tests/test_rezervasyon.py
import asyncio
from datetime import UTC, date, datetime

import pytest
from sqlalchemy import select

from app.models import (
    Booking, BookingDurumu, ClassSession, ClassType, Instructor,
    Member, Package, Room, SessionDurumu,
)
from app.services.hatalar import (
    DersDolu, DersIptalEdilmis, YetersizKredi, ZatenRezerve,
)
from app.services.kredi import bakiye, paket_tanimla
from app.services.rezervasyon import rezerve_et


async def _senaryo(db, *, kontenjan: int = 2, kredi_ver: bool = True):
    uye = Member(telefon="+905316033080", ad="Selin")
    tip = ClassType(ad="Barre", kontenjan=kontenjan, sure_dk=50)
    egitmen = Instructor(ad="Deniz")
    salon = Room(ad="Stüdyo")
    paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
    db.add_all([uye, tip, egitmen, salon, paket])
    await db.flush()

    oturum = ClassSession(
        baslangic=datetime(2026, 9, 1, 16, 0, tzinfo=UTC),
        class_type_id=tip.id, instructor_id=egitmen.id,
        room_id=salon.id, kontenjan=kontenjan,
    )
    db.add(oturum)
    await db.flush()

    if kredi_ver:
        await paket_tanimla(
            db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1)
        )
    return uye, oturum, paket


async def test_rezervasyon_dolu_sayiyi_artirir_ve_kredi_duser(db):
    uye, oturum, _ = await _senaryo(db)

    kayit = await rezerve_et(db, member_id=uye.id, session_id=oturum.id)

    await db.refresh(oturum)
    assert kayit.durum == BookingDurumu.BOOKED
    assert oturum.dolu_sayi == 1
    assert await bakiye(db, uye.id) == 7


async def test_kontenjan_dolunca_rezervasyon_reddedilir(db):
    uye, oturum, paket = await _senaryo(db, kontenjan=1)

    await rezerve_et(db, member_id=uye.id, session_id=oturum.id)

    baskasi = Member(telefon="+905321112233", ad="Ece")
    db.add(baskasi)
    await db.flush()
    await paket_tanimla(db, member_id=baskasi.id, package_id=paket.id, baslangic=date(2026, 9, 1))

    with pytest.raises(DersDolu):
        await rezerve_et(db, member_id=baskasi.id, session_id=oturum.id)


async def test_kredisi_olmayan_uye_rezervasyon_yapamaz(db):
    uye, oturum, _ = await _senaryo(db, kredi_ver=False)

    with pytest.raises(YetersizKredi):
        await rezerve_et(db, member_id=uye.id, session_id=oturum.id)

    await db.refresh(oturum)
    # Kredi kontrolü kontenjan artışından ÖNCE olmalı — reddedilen istek
    # kontenjandan yer çalmamalı
    assert oturum.dolu_sayi == 0


async def test_ayni_derse_iki_kez_rezervasyon_yapilamaz(db):
    uye, oturum, _ = await _senaryo(db)

    await rezerve_et(db, member_id=uye.id, session_id=oturum.id)

    with pytest.raises(ZatenRezerve):
        await rezerve_et(db, member_id=uye.id, session_id=oturum.id)


async def test_iptal_edilmis_derse_rezervasyon_yapilamaz(db):
    uye, oturum, _ = await _senaryo(db)
    oturum.durum = SessionDurumu.IPTAL
    await db.flush()

    with pytest.raises(DersIptalEdilmis):
        await rezerve_et(db, member_id=uye.id, session_id=oturum.id)
```

- [ ] **Step 4: Eşzamanlılık testini yaz**

Bu test `temiz_db` fixture'ını kullanır — iki ayrı bağlantının birbirinin satır kilidini görmesi gerekiyor.

```python
# tests/test_rezervasyon.py — dosyanın sonuna ekle
async def test_son_yere_ayni_anda_basan_iki_uyeden_yalniz_biri_kazanir(temiz_db):
    """Kontenjan yarışının gerçek sınaması.

    İki ayrı veritabanı bağlantısı son yer için aynı anda yarışır.
    PostgreSQL READ COMMITTED'da ikinci UPDATE birincinin satır kilidini
    bekler ve commit sonrası WHERE koşulunu YENİDEN değerlendirir; bu yüzden
    son yer iki kez satılamaz.
    """
    async with temiz_db() as hazirlik:
        tip = ClassType(ad="Barre", kontenjan=1, sure_dk=50)
        egitmen = Instructor(ad="Deniz")
        salon = Room(ad="Stüdyo")
        paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
        selin = Member(telefon="+905316033080", ad="Selin")
        ece = Member(telefon="+905321112233", ad="Ece")
        hazirlik.add_all([tip, egitmen, salon, paket, selin, ece])
        await hazirlik.flush()

        oturum = ClassSession(
            baslangic=datetime(2026, 9, 1, 16, 0, tzinfo=UTC),
            class_type_id=tip.id, instructor_id=egitmen.id,
            room_id=salon.id, kontenjan=1,
        )
        hazirlik.add(oturum)
        await hazirlik.flush()

        for uye in (selin, ece):
            await paket_tanimla(
                hazirlik, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1)
            )

        oturum_id, selin_id, ece_id = oturum.id, selin.id, ece.id
        await hazirlik.commit()

    async def dene(member_id: int) -> str:
        async with temiz_db() as oturum_db:
            try:
                await rezerve_et(oturum_db, member_id=member_id, session_id=oturum_id)
                await oturum_db.commit()
                return "kazandi"
            except DersDolu:
                await oturum_db.rollback()
                return "doldu"

    sonuclar = await asyncio.gather(dene(selin_id), dene(ece_id))

    assert sorted(sonuclar) == ["doldu", "kazandi"]

    async with temiz_db() as kontrol:
        guncel = await kontrol.get(ClassSession, oturum_id)
        assert guncel.dolu_sayi == 1

        kayitlar = await kontrol.execute(
            select(Booking).where(Booking.session_id == oturum_id)
        )
        assert len(list(kayitlar.scalars())) == 1
```

- [ ] **Step 5: Testleri çalıştır, başarısız olduklarını gör**

Run: `pytest tests/test_rezervasyon.py -v`
Beklenen: FAIL — `ModuleNotFoundError: No module named 'app.services.rezervasyon'`

- [ ] **Step 6: rezervasyon.py yaz**

```python
# app/services/rezervasyon.py
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import (
    Booking, BookingDurumu, BookingKaynagi, ClassSession,
    ClassType, LedgerTipi, SessionDurumu,
)
from app.services.hatalar import (
    DersDolu, DersIptalEdilmis, YetersizKredi, ZatenRezerve,
)
from app.services.kredi import bakiye, hareket_ekle


async def rezerve_et(
    db: AsyncSession,
    *,
    member_id: int,
    session_id: int,
    kaynak: BookingKaynagi = BookingKaynagi.APP,
) -> Booking:
    """Üyeyi derse kaydeder, kredisinden bir ders düşer.

    Sıra önemlidir: önce ucuz ve reddedici kontroller (iptal, çift kayıt,
    kredi), en son kontenjan artışı. Reddedilecek bir istek kontenjandan
    geçici olarak yer çalmamalı.
    """
    oturum = await db.get(ClassSession, session_id)
    if oturum is None:
        raise ValueError(f"Ders bulunamadı: {session_id}")
    if oturum.durum != SessionDurumu.AKTIF:
        raise DersIptalEdilmis("Bu ders iptal edilmiş")

    mevcut = await db.execute(
        select(Booking).where(
            Booking.member_id == member_id,
            Booking.session_id == session_id,
            Booking.durum == BookingDurumu.BOOKED,
        )
    )
    if mevcut.scalar_one_or_none() is not None:
        raise ZatenRezerve("Bu derse zaten kayıtlısın")

    if await bakiye(db, member_id) < 1:
        raise YetersizKredi("Ders paketinde yeterli hak yok")

    # Kontenjanı atomik olarak artır. Etkilenen satır 0 ise ders dolmuştur.
    # SELECT FOR UPDATE değil: bu tek round-trip ve deadlock üretmiyor.
    # "Önce say sonra ekle" ise çalışmaz — iki istek aynı sayıyı okur.
    sonuc = await db.execute(
        update(ClassSession)
        .where(
            ClassSession.id == session_id,
            ClassSession.dolu_sayi < ClassSession.kontenjan,
            ClassSession.durum == SessionDurumu.AKTIF,
        )
        .values(dolu_sayi=ClassSession.dolu_sayi + 1)
        .returning(ClassSession.dolu_sayi)
    )
    if sonuc.first() is None:
        raise DersDolu("Ders dolu")

    kayit = Booking(
        member_id=member_id,
        session_id=session_id,
        durum=BookingDurumu.BOOKED,
        kaynak=kaynak,
    )
    db.add(kayit)
    await db.flush()

    tip = await db.get(ClassType, oturum.class_type_id)
    await hareket_ekle(
        db,
        member_id=member_id,
        tip=LedgerTipi.BOOKING,
        miktar=-1,
        sebep=f"{tip.ad} — {oturum.baslangic:%d.%m.%Y %H:%M} UTC",
        booking_id=kayit.id,
    )
    return kayit
```

- [ ] **Step 7: Testleri çalıştır**

Run: `pytest tests/test_rezervasyon.py -v`
Beklenen: 6 PASS (eşzamanlılık testi dahil).

Eşzamanlılık testi kararsız (flaky) görünürse **testi zayıflatma** — gerçek bir yarış hatası bulmuş olabilirsin. `dolu_sayi` değerini ve kaç `Booking` satırı oluştuğunu logla.

- [ ] **Step 8: Migration üret ve uygula**

```bash
cd backend
alembic revision --autogenerate -m "rezervasyon: bookings ve waitlist_entries"
alembic upgrade head
```

Üretilen dosyayı aç: `uq_aktif_rezervasyon` **kısmi** index'inin `postgresql_where` ile geldiğini doğrula. Autogenerate kısmi index'i bazen tam unique olarak üretir — öyleyse elle düzelt, yoksa iptal edip yeniden rezerve etmek imkânsız olur.

- [ ] **Step 9: Commit**

```bash
git add backend/
git commit -m "feat(backend): rezervasyon ve kontenjan yarışı

Kontenjan tek atomik UPDATE ile artıyor; etkilenen satır 0 ise ders dolu.
PostgreSQL READ COMMITTED'da ikinci UPDATE birincinin kilidini bekleyip
WHERE'i yeniden değerlendirdiği için son yer iki kez satılamıyor.

Eşzamanlılık testi iki ayrı bağlantıyı gerçekten yarıştırıyor (temiz_db
fixture'ı) — rollback izolasyonunda bu yarış kurulamaz.

Kısmi unique index (durum='booked') aynı derse çift kaydı engelliyor ama
iptal edip yeniden rezerve etmeye izin veriyor."
```

---

### Task 8: İptal ve iade penceresi

**Files:**
- Create: `backend/app/services/iptal.py`
- Modify: `backend/app/services/hatalar.py`
- Create: `backend/tests/test_iptal.py`

**Interfaces:**
- Consumes: `Booking`, `BookingDurumu`, `ClassSession`, `ClassType`, `hareket_ekle`, `LedgerTipi`
- Produces:
  - `IptalSonucu` — dataclass: `booking: Booking`, `iade_edildi: bool`, `bosalan_yer: bool`
  - `iptal_et(db, *, booking_id: int, now: datetime) -> IptalSonucu`
  - `app.services.hatalar.ZatenIptal(SoboHata)`

**Sınır kararı (spec Global Constraints):** `now <= son_iptal_ani` ise iptal **penceredeki** iptaldir ve kredi iade edilir. Tam sınırda iptal hakkı vardır — sınır kullanıcı lehine yorumlanır. Bir saniyelik farkın üyenin dersini yakması, sistemin haksız algılanmasının en hızlı yoludur.

**Neden `now` parametre:** Servis asla `datetime.now()` çağırmaz. Sınır davranışını test etmenin tek güvenilir yolu zamanı dışarıdan vermektir; kütüphaneyle zaman dondurmak testi yavaşlatır ve saat dilimi hatalarını gizler.

- [ ] **Step 1: Testleri yaz (başarısız olacak)**

```python
# tests/test_iptal.py
from datetime import UTC, date, datetime, timedelta

import pytest

from app.models import (
    BookingDurumu, ClassSession, ClassType, Instructor, LedgerTipi,
    Member, Package, Room,
)
from app.services.hatalar import ZatenIptal
from app.services.iptal import iptal_et
from app.services.kredi import bakiye, paket_tanimla
from app.services.rezervasyon import rezerve_et

DERS_ANI = datetime(2026, 9, 1, 16, 0, tzinfo=UTC)


async def _rezervasyonlu_senaryo(db, *, iptal_penceresi_saat: int = 6):
    uye = Member(telefon="+905316033080", ad="Selin")
    tip = ClassType(
        ad="Barre", kontenjan=8, sure_dk=50,
        iptal_penceresi_saat=iptal_penceresi_saat,
    )
    egitmen = Instructor(ad="Deniz")
    salon = Room(ad="Stüdyo")
    paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
    db.add_all([uye, tip, egitmen, salon, paket])
    await db.flush()

    oturum = ClassSession(
        baslangic=DERS_ANI, class_type_id=tip.id, instructor_id=egitmen.id,
        room_id=salon.id, kontenjan=8,
    )
    db.add(oturum)
    await db.flush()

    await paket_tanimla(db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1))
    kayit = await rezerve_et(db, member_id=uye.id, session_id=oturum.id)
    return uye, oturum, kayit


async def test_pencere_icinde_iptal_krediyi_iade_eder(db):
    uye, oturum, kayit = await _rezervasyonlu_senaryo(db)
    assert await bakiye(db, uye.id) == 7

    sonuc = await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=8))

    assert sonuc.iade_edildi is True
    assert sonuc.bosalan_yer is True
    assert await bakiye(db, uye.id) == 8

    await db.refresh(oturum)
    assert oturum.dolu_sayi == 0


async def test_gec_iptal_krediyi_yakar_ama_yeri_bosaltir(db):
    uye, oturum, kayit = await _rezervasyonlu_senaryo(db)

    sonuc = await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=2))

    assert sonuc.iade_edildi is False
    assert sonuc.bosalan_yer is True
    assert await bakiye(db, uye.id) == 7  # kredi yandı

    await db.refresh(oturum)
    # Yer yine de boşalır — üye gelmeyecekse o yer başkasına açılmalı
    assert oturum.dolu_sayi == 0


async def test_tam_sinirda_iptal_hakki_vardir(db):
    """now == son_iptal_ani -> iade edilir. Sınır kullanıcı lehine."""
    uye, _, kayit = await _rezervasyonlu_senaryo(db, iptal_penceresi_saat=6)

    sonuc = await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=6))

    assert sonuc.iade_edildi is True
    assert await bakiye(db, uye.id) == 8


async def test_sinirdan_bir_saniye_sonra_gec_iptaldir(db):
    uye, _, kayit = await _rezervasyonlu_senaryo(db, iptal_penceresi_saat=6)

    sonuc = await iptal_et(
        db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=6) + timedelta(seconds=1)
    )

    assert sonuc.iade_edildi is False
    assert await bakiye(db, uye.id) == 7


async def test_iptal_penceresi_ders_tipine_gore_degisir(db):
    """Birebir dersin penceresi 24 saat olabilir."""
    uye, _, kayit = await _rezervasyonlu_senaryo(db, iptal_penceresi_saat=24)

    sonuc = await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=8))

    assert sonuc.iade_edildi is False  # 8 saat kala, 24 saatlik pencerede geç
    assert await bakiye(db, uye.id) == 7


async def test_ayni_rezervasyon_iki_kez_iptal_edilemez(db):
    _, _, kayit = await _rezervasyonlu_senaryo(db)
    await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=8))

    with pytest.raises(ZatenIptal):
        await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=8))


async def test_iptal_ledgerda_iz_birakir(db):
    from sqlalchemy import select

    from app.models import CreditLedger

    uye, _, kayit = await _rezervasyonlu_senaryo(db)
    await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=2))

    sonuc = await db.execute(
        select(CreditLedger).where(CreditLedger.member_id == uye.id)
        .order_by(CreditLedger.id)
    )
    tipler = [k.tip for k in sonuc.scalars()]
    assert tipler == [
        LedgerTipi.PURCHASE, LedgerTipi.BOOKING, LedgerTipi.LATE_CANCEL,
    ]
```

- [ ] **Step 2: Testleri çalıştır, başarısız olduklarını gör**

Run: `pytest tests/test_iptal.py -v`
Beklenen: FAIL — `ModuleNotFoundError: No module named 'app.services.iptal'`

- [ ] **Step 3: hatalar.py'ye ZatenIptal ekle**

```python
# app/services/hatalar.py — dosyanın sonuna ekle
class ZatenIptal(SoboHata):
    pass
```

- [ ] **Step 4: iptal.py yaz**

```python
# app/services/iptal.py
from dataclasses import dataclass
from datetime import datetime, timedelta

from sqlalchemy import update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import (
    Booking, BookingDurumu, ClassSession, ClassType, LedgerTipi,
)
from app.services.hatalar import ZatenIptal
from app.services.kredi import hareket_ekle


@dataclass(frozen=True)
class IptalSonucu:
    booking: Booking
    iade_edildi: bool
    bosalan_yer: bool


async def iptal_et(db: AsyncSession, *, booking_id: int, now: datetime) -> IptalSonucu:
    """Rezervasyonu iptal eder.

    Pencerede iptal: kredi iade edilir (CANCEL_REFUND, +1).
    Geç iptal: kredi yanar (LATE_CANCEL, 0) — ama satır yine yazılır ki
    üye "neden bir dersim eksik" diye sorduğunda cevap tarihçede olsun.

    Her iki durumda da KONTENJAN BOŞALIR. Üye gelmeyecekse o yer başkasına
    açılmalıdır; geç iptali cezalandırmanın yolu yeri boş tutmak değil,
    krediyi yakmaktır.
    """
    kayit = await db.get(Booking, booking_id)
    if kayit is None:
        raise ValueError(f"Rezervasyon bulunamadı: {booking_id}")
    if kayit.durum != BookingDurumu.BOOKED:
        raise ZatenIptal("Bu rezervasyon zaten kapatılmış")

    oturum = await db.get(ClassSession, kayit.session_id)
    tip = await db.get(ClassType, oturum.class_type_id)

    son_iptal_ani = oturum.baslangic - timedelta(hours=tip.iptal_penceresi_saat)
    # Sınır kullanıcı lehine: tam sınırda iptal hakkı vardır.
    pencerede = now <= son_iptal_ani

    kayit.durum = BookingDurumu.CANCELLED
    kayit.cancelled_at = now

    # Kontenjanı atomik olarak azalt. dolu_sayi > 0 koşulu, çift iptalin
    # sayacı eksiye düşürmesini veritabanı seviyesinde engeller.
    sonuc = await db.execute(
        update(ClassSession)
        .where(ClassSession.id == oturum.id, ClassSession.dolu_sayi > 0)
        .values(dolu_sayi=ClassSession.dolu_sayi - 1)
        .returning(ClassSession.dolu_sayi)
    )
    bosalan_yer = sonuc.first() is not None

    if pencerede:
        await hareket_ekle(
            db, member_id=kayit.member_id, tip=LedgerTipi.CANCEL_REFUND, miktar=1,
            sebep=f"{tip.ad} — pencerede iptal", booking_id=kayit.id,
        )
    else:
        kalan_saat = (oturum.baslangic - now).total_seconds() / 3600
        await hareket_ekle(
            db, member_id=kayit.member_id, tip=LedgerTipi.LATE_CANCEL, miktar=0,
            sebep=f"{tip.ad} — ders saatine {kalan_saat:.1f} saat kala iptal",
            booking_id=kayit.id,
        )

    await db.flush()
    return IptalSonucu(booking=kayit, iade_edildi=pencerede, bosalan_yer=bosalan_yer)
```

- [ ] **Step 5: Testleri çalıştır**

Run: `pytest tests/test_iptal.py -v`
Beklenen: 7 PASS.

- [ ] **Step 6: Commit**

```bash
git add backend/
git commit -m "feat(backend): iptal ve iade penceresi

Sınır kullanıcı lehine: now <= son_iptal_ani ise iade edilir. Bir saniyelik
farkın üyenin dersini yakması sistemin haksız algılanmasının en hızlı yolu.

Geç iptalde de kontenjan boşalır — üye gelmeyecekse yer başkasına açılmalı.
Ceza yeri boş tutmak değil, krediyi yakmak."
```

---

### Task 9: Bekleme listesi

**Files:**
- Create: `backend/app/services/bekleme.py`
- Modify: `backend/app/services/hatalar.py`
- Create: `backend/tests/test_bekleme.py`

**Interfaces:**
- Consumes: `WaitlistEntry` (Task 7), `ClassSession`, `rezerve_et`
- Produces:
  - `TEKLIF_SURESI_DK = 20`
  - `siraya_gir(db, *, member_id, session_id) -> WaitlistEntry`
  - `sirayi_ilerlet(db, *, session_id, now: datetime) -> WaitlistEntry | None` — sıradakine teklif açar
  - `teklifi_kullan(db, *, entry_id, now: datetime) -> Booking`
  - Hatalar: `DersDoluDegil`, `TeklifSuresiDolmus`, `ZatenSirada`

**Teklif süresi neden 20 dakika ve neden derse yaklaşınca kısalıyor:** Yer açıldığında sıradaki üyeye bildirim gider ve 20 dakika hakkı olur. Ama ders 10 dakika sonra başlıyorsa 20 dakika beklemek yeri tamamen boşa harcar. Bu yüzden teklif süresi `min(20 dk, derse kalan süre)` olur.

**Redis kullanılmıyor:** `teklif_bitis` bir timestamp sütunu olarak yeterli. İkinci bir altyapı bileşeni, tek bir zaman aşımı için gereksiz.

- [ ] **Step 1: Testleri yaz (başarısız olacak)**

```python
# tests/test_bekleme.py
from datetime import UTC, date, datetime, timedelta

import pytest

from app.models import (
    ClassSession, ClassType, Instructor, Member, Package, Room,
)
from app.services.bekleme import (
    TEKLIF_SURESI_DK, siraya_gir, sirayi_ilerlet, teklifi_kullan,
)
from app.services.hatalar import (
    DersDoluDegil, TeklifSuresiDolmus, ZatenSirada,
)
from app.services.iptal import iptal_et
from app.services.kredi import bakiye, paket_tanimla
from app.services.rezervasyon import rezerve_et

DERS_ANI = datetime(2026, 9, 1, 16, 0, tzinfo=UTC)


async def _dolu_ders(db):
    """Kontenjanı 1 olan ve dolu bir ders; ayrıca sıraya girecek iki üye."""
    tip = ClassType(ad="Barre", kontenjan=1, sure_dk=50)
    egitmen = Instructor(ad="Deniz")
    salon = Room(ad="Stüdyo")
    paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
    selin = Member(telefon="+905316033080", ad="Selin")
    ece = Member(telefon="+905321112233", ad="Ece")
    zeynep = Member(telefon="+905334445566", ad="Zeynep")
    db.add_all([tip, egitmen, salon, paket, selin, ece, zeynep])
    await db.flush()

    oturum = ClassSession(
        baslangic=DERS_ANI, class_type_id=tip.id, instructor_id=egitmen.id,
        room_id=salon.id, kontenjan=1,
    )
    db.add(oturum)
    await db.flush()

    for uye in (selin, ece, zeynep):
        await paket_tanimla(db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1))

    kayit = await rezerve_et(db, member_id=selin.id, session_id=oturum.id)
    return oturum, selin, ece, zeynep, kayit


async def test_dolu_derse_siraya_girilir(db):
    oturum, _, ece, _, _ = await _dolu_ders(db)

    kayit = await siraya_gir(db, member_id=ece.id, session_id=oturum.id)

    assert kayit.sira == 1
    assert kayit.teklif_bitis is None
    assert kayit.kullanildi is False


async def test_sira_numaralari_girilme_sirasina_gore_artar(db):
    oturum, _, ece, zeynep, _ = await _dolu_ders(db)

    birinci = await siraya_gir(db, member_id=ece.id, session_id=oturum.id)
    ikinci = await siraya_gir(db, member_id=zeynep.id, session_id=oturum.id)

    assert (birinci.sira, ikinci.sira) == (1, 2)


async def test_dolu_olmayan_derse_siraya_girilemez(db):
    oturum, selin, ece, _, kayit = await _dolu_ders(db)
    await iptal_et(db, booking_id=kayit.id, now=DERS_ANI - timedelta(hours=8))

    with pytest.raises(DersDoluDegil):
        await siraya_gir(db, member_id=ece.id, session_id=oturum.id)


async def test_ayni_derse_iki_kez_siraya_girilemez(db):
    oturum, _, ece, _, _ = await _dolu_ders(db)
    await siraya_gir(db, member_id=ece.id, session_id=oturum.id)

    with pytest.raises(ZatenSirada):
        await siraya_gir(db, member_id=ece.id, session_id=oturum.id)


async def test_yer_acilinca_siradakine_teklif_verilir(db):
    oturum, _, ece, zeynep, kayit = await _dolu_ders(db)
    await siraya_gir(db, member_id=ece.id, session_id=oturum.id)
    await siraya_gir(db, member_id=zeynep.id, session_id=oturum.id)

    an = DERS_ANI - timedelta(hours=8)
    await iptal_et(db, booking_id=kayit.id, now=an)
    teklif = await sirayi_ilerlet(db, session_id=oturum.id, now=an)

    assert teklif is not None
    assert teklif.member_id == ece.id
    assert teklif.teklif_bitis == an + timedelta(minutes=TEKLIF_SURESI_DK)


async def test_derse_yakinsa_teklif_suresi_kisalir(db):
    """Ders 10 dakika sonra başlıyorsa 20 dakika beklemek yeri boşa harcar."""
    oturum, _, ece, _, kayit = await _dolu_ders(db)
    await siraya_gir(db, member_id=ece.id, session_id=oturum.id)

    an = DERS_ANI - timedelta(minutes=10)
    await iptal_et(db, booking_id=kayit.id, now=an)
    teklif = await sirayi_ilerlet(db, session_id=oturum.id, now=an)

    assert teklif.teklif_bitis == DERS_ANI


async def test_teklif_kullanilinca_rezervasyon_olusur(db):
    oturum, _, ece, _, kayit = await _dolu_ders(db)
    await siraya_gir(db, member_id=ece.id, session_id=oturum.id)

    an = DERS_ANI - timedelta(hours=8)
    await iptal_et(db, booking_id=kayit.id, now=an)
    teklif = await sirayi_ilerlet(db, session_id=oturum.id, now=an)

    yeni = await teklifi_kullan(db, entry_id=teklif.id, now=an + timedelta(minutes=5))

    assert yeni.member_id == ece.id
    await db.refresh(oturum)
    assert oturum.dolu_sayi == 1
    assert await bakiye(db, ece.id) == 7


async def test_suresi_dolmus_teklif_kullanilamaz(db):
    oturum, _, ece, _, kayit = await _dolu_ders(db)
    await siraya_gir(db, member_id=ece.id, session_id=oturum.id)

    an = DERS_ANI - timedelta(hours=8)
    await iptal_et(db, booking_id=kayit.id, now=an)
    teklif = await sirayi_ilerlet(db, session_id=oturum.id, now=an)

    with pytest.raises(TeklifSuresiDolmus):
        await teklifi_kullan(
            db, entry_id=teklif.id, now=an + timedelta(minutes=TEKLIF_SURESI_DK + 1)
        )


async def test_teklif_suresi_dolunca_sira_bir_sonrakine_gecer(db):
    oturum, _, ece, zeynep, kayit = await _dolu_ders(db)
    await siraya_gir(db, member_id=ece.id, session_id=oturum.id)
    await siraya_gir(db, member_id=zeynep.id, session_id=oturum.id)

    an = DERS_ANI - timedelta(hours=8)
    await iptal_et(db, booking_id=kayit.id, now=an)
    await sirayi_ilerlet(db, session_id=oturum.id, now=an)

    sonraki = await sirayi_ilerlet(
        db, session_id=oturum.id, now=an + timedelta(minutes=TEKLIF_SURESI_DK + 1)
    )

    assert sonraki is not None
    assert sonraki.member_id == zeynep.id


async def test_bos_sirada_ilerletmek_none_doner(db):
    oturum, _, _, _, kayit = await _dolu_ders(db)
    an = DERS_ANI - timedelta(hours=8)
    await iptal_et(db, booking_id=kayit.id, now=an)

    assert await sirayi_ilerlet(db, session_id=oturum.id, now=an) is None
```

- [ ] **Step 2: Testleri çalıştır, başarısız olduklarını gör**

Run: `pytest tests/test_bekleme.py -v`
Beklenen: FAIL — `ModuleNotFoundError: No module named 'app.services.bekleme'`

- [ ] **Step 3: hatalar.py'ye yeni hataları ekle**

```python
# app/services/hatalar.py — dosyanın sonuna ekle
class DersDoluDegil(SoboHata):
    pass


class TeklifSuresiDolmus(SoboHata):
    pass


class ZatenSirada(SoboHata):
    pass
```

- [ ] **Step 4: bekleme.py yaz**

```python
# app/services/bekleme.py
from datetime import datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Booking, BookingKaynagi, ClassSession, WaitlistEntry
from app.services.hatalar import (
    DersDoluDegil, TeklifSuresiDolmus, ZatenSirada,
)
from app.services.rezervasyon import rezerve_et

TEKLIF_SURESI_DK = 20


async def siraya_gir(
    db: AsyncSession, *, member_id: int, session_id: int
) -> WaitlistEntry:
    """Dolu bir derse bekleme sırası kaydı açar."""
    oturum = await db.get(ClassSession, session_id)
    if oturum is None:
        raise ValueError(f"Ders bulunamadı: {session_id}")
    if oturum.dolu_sayi < oturum.kontenjan:
        raise DersDoluDegil("Derste yer var, doğrudan rezervasyon yapılabilir")

    mevcut = await db.execute(
        select(WaitlistEntry).where(
            WaitlistEntry.member_id == member_id,
            WaitlistEntry.session_id == session_id,
        )
    )
    if mevcut.scalar_one_or_none() is not None:
        raise ZatenSirada("Bu dersin bekleme listesindesin")

    sonuc = await db.execute(
        select(func.coalesce(func.max(WaitlistEntry.sira), 0)).where(
            WaitlistEntry.session_id == session_id
        )
    )
    kayit = WaitlistEntry(
        member_id=member_id,
        session_id=session_id,
        sira=int(sonuc.scalar_one()) + 1,
    )
    db.add(kayit)
    await db.flush()
    return kayit


async def sirayi_ilerlet(
    db: AsyncSession, *, session_id: int, now: datetime
) -> WaitlistEntry | None:
    """Sıradaki uygun üyeye teklif açar. Sıra boşsa None döner.

    Teklif süresi `min(20 dk, derse kalan süre)`: ders 10 dakika sonra
    başlıyorsa 20 dakika beklemek yeri tamamen boşa harcar.
    """
    oturum = await db.get(ClassSession, session_id)
    if oturum is None:
        raise ValueError(f"Ders bulunamadı: {session_id}")

    sonuc = await db.execute(
        select(WaitlistEntry)
        .where(
            WaitlistEntry.session_id == session_id,
            WaitlistEntry.kullanildi.is_(False),
        )
        .order_by(WaitlistEntry.sira)
    )
    for kayit in sonuc.scalars():
        # Süresi dolmuş teklifleri atla — bunlar sırayı kaybetmiştir
        if kayit.teklif_bitis is not None and kayit.teklif_bitis <= now:
            continue
        if kayit.teklif_bitis is not None:
            return kayit  # hâlâ açık bir teklif var, yenisini verme

        kayit.teklif_bitis = min(
            now + timedelta(minutes=TEKLIF_SURESI_DK), oturum.baslangic
        )
        await db.flush()
        return kayit

    return None


async def teklifi_kullan(
    db: AsyncSession, *, entry_id: int, now: datetime
) -> Booking:
    """Bekleme listesi teklifini rezervasyona çevirir."""
    kayit = await db.get(WaitlistEntry, entry_id)
    if kayit is None:
        raise ValueError(f"Bekleme kaydı bulunamadı: {entry_id}")
    if kayit.teklif_bitis is None:
        raise TeklifSuresiDolmus("Bu kayda henüz teklif açılmadı")
    if now > kayit.teklif_bitis:
        raise TeklifSuresiDolmus("Teklif süresi doldu")

    rezervasyon = await rezerve_et(
        db,
        member_id=kayit.member_id,
        session_id=kayit.session_id,
        kaynak=BookingKaynagi.APP,
    )
    kayit.kullanildi = True
    await db.flush()
    return rezervasyon
```

- [ ] **Step 5: Testleri çalıştır**

Run: `pytest tests/test_bekleme.py -v`
Beklenen: 10 PASS.

- [ ] **Step 6: Commit**

```bash
git add backend/
git commit -m "feat(backend): bekleme listesi

Teklif süresi min(20dk, derse kalan süre) — ders 10 dakika sonra
başlıyorsa 20 dakika beklemek yeri tamamen boşa harcar.

Redis kullanılmadı: teklif_bitis bir timestamp sütunu olarak yeterli,
tek bir zaman aşımı için ikinci altyapı bileşeni gereksiz."
```

---

### Task 10: Yoklama ve gelmeme (no-show)

**Files:**
- Create: `backend/app/services/yoklama.py`
- Create: `backend/tests/test_yoklama.py`

**Interfaces:**
- Consumes: `Booking`, `BookingDurumu`, `ClassSession`, `ClassType`, `hareket_ekle`, `LedgerTipi`
- Produces:
  - `YoklamaSonucu` — dataclass: `gelen: int`, `gelmeyen: int`
  - `yoklama_al(db, *, session_id: int, gelen_member_ids: set[int], now: datetime) -> YoklamaSonucu`

**Neden tek çağrıda toplu yoklama:** Eğitmen ders sonunda panelde listeye bakıp gelenleri işaretler ve bir kez kaydeder. Üye üye API çağrısı yapmak hem yavaş hem de yarım kalmış yoklama durumu üretir — beş kişi işaretlenip altıncıda bağlantı koparsa ders yarı işlenmiş kalır.

**No-show kredi yakar ama kontenjanı geri vermez:** Ders geçmiştir, o yerin başkasına satılması diye bir şey yoktur. `dolu_sayi` dokunulmadan bırakılır — geçmiş dersin kaç kişiyle yapıldığı bilgisi korunmalı.

- [ ] **Step 1: Testleri yaz (başarısız olacak)**

```python
# tests/test_yoklama.py
from datetime import UTC, date, datetime, timedelta

from sqlalchemy import select

from app.models import (
    Booking, BookingDurumu, ClassSession, ClassType, CreditLedger,
    Instructor, LedgerTipi, Member, Package, Room,
)
from app.services.kredi import bakiye, paket_tanimla
from app.services.rezervasyon import rezerve_et
from app.services.yoklama import yoklama_al

DERS_ANI = datetime(2026, 9, 1, 16, 0, tzinfo=UTC)
DERS_SONRASI = DERS_ANI + timedelta(hours=1)


async def _iki_kayitli_ders(db):
    tip = ClassType(ad="Barre", kontenjan=8, sure_dk=50)
    egitmen = Instructor(ad="Deniz")
    salon = Room(ad="Stüdyo")
    paket = Package(ad="8 Ders", ders_adedi=8, gecerlilik_gun=60, fiyat_kurus=480000)
    selin = Member(telefon="+905316033080", ad="Selin")
    ece = Member(telefon="+905321112233", ad="Ece")
    db.add_all([tip, egitmen, salon, paket, selin, ece])
    await db.flush()

    oturum = ClassSession(
        baslangic=DERS_ANI, class_type_id=tip.id, instructor_id=egitmen.id,
        room_id=salon.id, kontenjan=8,
    )
    db.add(oturum)
    await db.flush()

    for uye in (selin, ece):
        await paket_tanimla(db, member_id=uye.id, package_id=paket.id, baslangic=date(2026, 9, 1))
        await rezerve_et(db, member_id=uye.id, session_id=oturum.id)

    return oturum, selin, ece


async def test_gelenler_attended_gelmeyenler_no_show_olur(db):
    oturum, selin, ece = await _iki_kayitli_ders(db)

    sonuc = await yoklama_al(
        db, session_id=oturum.id, gelen_member_ids={selin.id}, now=DERS_SONRASI
    )

    assert (sonuc.gelen, sonuc.gelmeyen) == (1, 1)

    kayitlar = await db.execute(
        select(Booking).where(Booking.session_id == oturum.id).order_by(Booking.id)
    )
    durumlar = {k.member_id: k.durum for k in kayitlar.scalars()}
    assert durumlar[selin.id] == BookingDurumu.ATTENDED
    assert durumlar[ece.id] == BookingDurumu.NO_SHOW


async def test_no_show_krediyi_yakar_gelen_etkilenmez(db):
    oturum, selin, ece = await _iki_kayitli_ders(db)
    assert await bakiye(db, selin.id) == 7
    assert await bakiye(db, ece.id) == 7

    await yoklama_al(
        db, session_id=oturum.id, gelen_member_ids={selin.id}, now=DERS_SONRASI
    )

    # İkisinin de bakiyesi 7 — rezervasyonda zaten düşmüştü, no-show iade etmez
    assert await bakiye(db, selin.id) == 7
    assert await bakiye(db, ece.id) == 7

    # Ama gelmeyen için ledger'da iz var
    izler = await db.execute(
        select(CreditLedger).where(
            CreditLedger.member_id == ece.id,
            CreditLedger.tip == LedgerTipi.NO_SHOW,
        )
    )
    iz = izler.scalar_one()
    assert iz.miktar == 0


async def test_no_show_kontenjani_geri_vermez(db):
    """Ders geçmiştir; o yerin başkasına satılması diye bir şey yok."""
    oturum, selin, _ = await _iki_kayitli_ders(db)

    await yoklama_al(
        db, session_id=oturum.id, gelen_member_ids={selin.id}, now=DERS_SONRASI
    )

    await db.refresh(oturum)
    assert oturum.dolu_sayi == 2


async def test_iptal_edilmis_rezervasyon_yoklamaya_girmez(db):
    from datetime import timedelta as td

    from app.services.iptal import iptal_et

    oturum, selin, ece = await _iki_kayitli_ders(db)
    kayitlar = await db.execute(
        select(Booking).where(Booking.member_id == ece.id)
    )
    await iptal_et(
        db, booking_id=kayitlar.scalar_one().id, now=DERS_ANI - td(hours=8)
    )

    sonuc = await yoklama_al(
        db, session_id=oturum.id, gelen_member_ids={selin.id}, now=DERS_SONRASI
    )

    assert (sonuc.gelen, sonuc.gelmeyen) == (1, 0)


async def test_yoklama_iki_kez_alinirsa_ikinci_kez_kredi_yakmaz(db):
    """İdempotanlık: eğitmen kaydet'e iki kez basarsa ceza iki kez yazılmamalı."""
    oturum, selin, ece = await _iki_kayitli_ders(db)

    await yoklama_al(db, session_id=oturum.id, gelen_member_ids={selin.id}, now=DERS_SONRASI)
    sonuc = await yoklama_al(db, session_id=oturum.id, gelen_member_ids={selin.id}, now=DERS_SONRASI)

    assert (sonuc.gelen, sonuc.gelmeyen) == (0, 0)

    izler = await db.execute(
        select(CreditLedger).where(
            CreditLedger.member_id == ece.id,
            CreditLedger.tip == LedgerTipi.NO_SHOW,
        )
    )
    assert len(list(izler.scalars())) == 1
```

- [ ] **Step 2: Testleri çalıştır, başarısız olduklarını gör**

Run: `pytest tests/test_yoklama.py -v`
Beklenen: FAIL — `ModuleNotFoundError: No module named 'app.services.yoklama'`

- [ ] **Step 3: yoklama.py yaz**

```python
# app/services/yoklama.py
from dataclasses import dataclass
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import (
    Booking, BookingDurumu, ClassSession, ClassType, LedgerTipi,
)
from app.services.kredi import hareket_ekle


@dataclass(frozen=True)
class YoklamaSonucu:
    gelen: int
    gelmeyen: int


async def yoklama_al(
    db: AsyncSession,
    *,
    session_id: int,
    gelen_member_ids: set[int],
    now: datetime,
) -> YoklamaSonucu:
    """Dersin yoklamasını tek işlemde alır.

    Eğitmen panelde listeye bakıp gelenleri işaretler ve bir kez kaydeder.
    Üye üye çağrı yapmak yarım kalmış yoklama üretir — beşinci kişide
    bağlantı koparsa ders yarı işlenmiş kalır.

    İdempotenttir: yalnız hâlâ BOOKED durumdaki kayıtlar işlenir. Eğitmen
    kaydet'e iki kez basarsa ikinci çağrı hiçbir şey yapmaz ve no-show
    cezası iki kez yazılmaz.

    No-show KONTENJANI GERİ VERMEZ: ders geçmiştir, o yerin başkasına
    satılması diye bir şey yok. Geçmiş dersin kaç kişiyle yapıldığı bilgisi
    de korunmalı.
    """
    oturum = await db.get(ClassSession, session_id)
    if oturum is None:
        raise ValueError(f"Ders bulunamadı: {session_id}")
    tip = await db.get(ClassType, oturum.class_type_id)

    sonuc = await db.execute(
        select(Booking).where(
            Booking.session_id == session_id,
            Booking.durum == BookingDurumu.BOOKED,
        )
    )

    gelen = gelmeyen = 0
    for kayit in sonuc.scalars():
        if kayit.member_id in gelen_member_ids:
            kayit.durum = BookingDurumu.ATTENDED
            gelen += 1
        else:
            kayit.durum = BookingDurumu.NO_SHOW
            gelmeyen += 1
            await hareket_ekle(
                db,
                member_id=kayit.member_id,
                tip=LedgerTipi.NO_SHOW,
                miktar=0,
                sebep=f"{tip.ad} — {oturum.baslangic:%d.%m.%Y %H:%M} UTC dersine gelinmedi",
                booking_id=kayit.id,
            )

    await db.flush()
    return YoklamaSonucu(gelen=gelen, gelmeyen=gelmeyen)
```

- [ ] **Step 4: Testleri çalıştır**

Run: `pytest tests/test_yoklama.py -v`
Beklenen: 5 PASS.

- [ ] **Step 5: Tüm test paketini çalıştır**

Run: `pytest tests/ -v`
Beklenen: 47 PASS. Hiçbir test atlanmamalı.

- [ ] **Step 6: Migration zincirini boş veritabanında doğrula**

```bash
cd backend
docker compose down -v && docker compose up -d db
sleep 5
alembic upgrade head
```

Beklenen: hatasız. Bu, migration'ların gerçekten sıfırdan çalıştığının tek kanıtı — geliştirme veritabanında `upgrade head` çalışması bunu göstermez.

- [ ] **Step 7: Commit**

```bash
git add backend/
git commit -m "feat(backend): yoklama ve gelmeme

Tek çağrıda toplu yoklama — üye üye çağrı yarım kalmış yoklama üretir.
İdempotent: yalnız BOOKED kayıtlar işlenir, ikinci kayıt no-show cezasını
tekrar yazmaz.

No-show kontenjanı geri vermez: ders geçmiştir, geçmiş dersin kaç kişiyle
yapıldığı bilgisi korunmalı."
```

---

## Kapsam Notu — Faz 1'de Bilerek Yapılmayanlar

Bu plan domain çekirdeğini bitirir. Aşağıdakiler **sonraki fazlara** aittir ve burada eksik değildir:

| Konu | Nereye ait | Neden |
|---|---|---|
| FastAPI router'ları, HTTP katmanı | Faz 2 | Endpoint tasarımı admin panelinin ihtiyacına göre şekillenmeli |
| Telefon + SMS OTP kimlik doğrulama | Faz 2 | Sağlayıcı seçimi (Netgsm / İletimerkezi) açık soru |
| Push bildirim gönderimi | Faz 5 | iOS uygulaması gelmeden test edilemez |
| `expire` ledger tipinin zamanlanmış işi | Faz 2 | Tip tanımlı; işi çalıştıracak scheduler API katmanıyla gelir |
| KVKK aydınlatma metni içeriği | Ürün | Hukuki metin, mühendislik kararı değil |
| Seed verisi (gerçek ders tipleri, paketler) | Faz 2 | İşletmeden V1–V9 teyidi bekleniyor |

---

## Self-Review

**1. Spec kapsamı.** Spec §5.1'deki her tablo bir görevde karşılanıyor: `members`/`instructors` → Task 2 · `class_types`/`rooms`/`schedule_templates`/`class_sessions` → Task 3 · `packages`/`member_packages`/`credit_ledger` → Task 5 · `bookings`/`waitlist_entries` → Task 7. `devices` ve `announcements` push bildirimine ait, Faz 5'e bırakıldı ve yukarıdaki tabloda açıkça işaretlendi. §5.2'deki üç mekanizma → Task 7, 6, 9. §5.3'teki kararlardan zaman dilimi (Task 4), KVKK rıza alanları (Task 2) ve yetki modeli (Faz 2, auth ile) yerleşti.

**2. Placeholder taraması.** "TBD", "uygun hata yönetimi ekle", "yukarıdakiler için test yaz" türü ifade yok. Her adım çalıştırılabilir kod veya çalıştırılabilir komut içeriyor.

**3. Tip tutarlılığı.** `hareket_ekle` imzası Task 6'da tanımlandı; Task 7, 8, 10 aynı anahtar kelimelerle çağırıyor (`member_id`, `tip`, `miktar`, `sebep`, `booking_id`). `rezerve_et` Task 7'de tanımlandı, Task 9 aynı imzayla çağırıyor. `SessionDurumu`/`BookingDurumu` StrEnum olduğu için `String` sütunlarla doğrudan karşılaştırılabiliyor. Task 3'teki `uq_salon_saat` kısıt adı Task 4'te `on_conflict_do_nothing(constraint=...)` içinde birebir kullanılıyor.

**4. Bulunan ve düzeltilen:** `WaitlistEntry` başta Task 9'a konmuştu ama `bookings` ile aynı migration'da olması gerekiyor (ikisi de aynı konuya ait ve `rezervasyon.py` modülünü paylaşıyor) — Task 7'ye taşındı.

---

## Execution Handoff

Plan tamamlandı ve `docs/superpowers/plans/2026-08-25-sobo-backend-cekirdegi.md` dosyasına kaydedildi. İki yürütme seçeneği var:

**1. Subagent-Driven (önerilen)** — her görev için taze bir subagent, görevler arasında inceleme, hızlı iterasyon.

**2. Inline Execution** — görevler bu oturumda, kontrol noktalarıyla toplu yürütülür.

Hangisi?
