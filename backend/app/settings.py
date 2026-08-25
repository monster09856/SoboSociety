from pydantic_settings import BaseSettings, SettingsConfigDict


class Ayarlar(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+asyncpg://sobo:sobo@localhost:5433/sobo"
    test_database_url: str = "postgresql+asyncpg://sobo:sobo@localhost:5433/sobo_test"


ayarlar = Ayarlar()
