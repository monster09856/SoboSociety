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
