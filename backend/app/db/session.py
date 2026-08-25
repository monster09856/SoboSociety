from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.settings import ayarlar

motor = create_async_engine(ayarlar.database_url, pool_pre_ping=True)

OturumFabrikasi = async_sessionmaker(
    motor,
    class_=AsyncSession,
    expire_on_commit=False,
)
