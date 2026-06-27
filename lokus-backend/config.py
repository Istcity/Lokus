"""Lokus Geo Backend yapılandırması."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+asyncpg://lokus:lokus@localhost:5432/lokus_geo"
    use_mock_data: bool = True
    rate_limit_per_minute: int = 30
    cors_origins: str = "*"
    enable_etl_scheduler: bool = False
    app_name: str = "Lokus Geo API"
    app_version: str = "1.0.0"
    tcmb_evds_api_key: str = ""


settings = Settings()
