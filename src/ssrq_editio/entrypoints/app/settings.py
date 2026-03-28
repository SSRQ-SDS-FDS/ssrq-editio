from functools import cache
from typing import Literal

from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

Env = Literal["development", "staging", "production"]


class AppSettings(BaseSettings):
    """Application settings loaded from environment variables."""

    app_env: Env = "development"
    release: str | None = None
    sentry_dsn: SecretStr | None = None
    editio_view_cache_maxsize: int = Field(default=128, ge=1)
    editio_view_cache_ttl_seconds: int = Field(default=900, ge=1)

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


@cache
def get_settings() -> AppSettings:
    return AppSettings()
