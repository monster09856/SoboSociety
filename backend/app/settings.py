from pydantic_settings import BaseSettings, SettingsConfigDict


class Ayarlar(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+asyncpg://sobo:sobo@localhost:5433/sobo"
    test_database_url: str = "postgresql+asyncpg://sobo:sobo@localhost:5433/sobo_test"

    secret_key: str = "sobo-secret-key-change-in-production-2026"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7
    admin_telefons: list[str] = ["+905316033080", "+905555555555", "+905000000000"]

    # SMS Konfigürasyonu
    sms_provider: str = "mock"  # "mock" | "netgsm" | "iletimerkezi"
    sms_user: str = ""
    sms_password: str = ""
    sms_header: str = "SOBO"


ayarlar = Ayarlar()
