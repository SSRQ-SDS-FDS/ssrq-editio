import pytest
from pydantic import ValidationError

from ssrq_editio.entrypoints.app.settings import get_settings


@pytest.fixture(autouse=True)
def clear_settings_cache() -> None:
    get_settings.cache_clear()


def test_get_settings_uses_defaults() -> None:
    settings = get_settings()

    assert settings.app_env == "development"
    assert settings.editio_view_cache_maxsize == 128
    assert settings.editio_view_cache_ttl_seconds == 900
    assert settings.sentry_dsn is None


def test_get_settings_reads_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("APP_ENV", "staging")
    monkeypatch.setenv("SENTRY_DSN", "https://abc@example.com/1")
    monkeypatch.setenv("EDITIO_VIEW_CACHE_MAXSIZE", "256")
    monkeypatch.setenv("EDITIO_VIEW_CACHE_TTL_SECONDS", "1200")

    settings = get_settings()

    assert settings.app_env == "staging"
    assert settings.sentry_dsn is not None
    assert settings.editio_view_cache_maxsize == 256
    assert settings.editio_view_cache_ttl_seconds == 1200


def test_get_settings_validates_cache_values(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("EDITIO_VIEW_CACHE_MAXSIZE", "0")

    with pytest.raises(ValidationError):
        get_settings()
