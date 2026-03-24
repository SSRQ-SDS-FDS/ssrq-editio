import logging
from typing import Any

import pytest
from pydantic import SecretStr

from ssrq_editio.entrypoints.app.settings import AppSettings
from ssrq_editio.services.monitoring import setup_error_monitoring


def test_setup_error_monitoring_skips_development(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    called = {"value": False}

    def fake_init(**_: Any) -> None:
        called["value"] = True

    monkeypatch.setattr("ssrq_editio.services.monitoring.sentry_sdk.init", fake_init)

    setup_error_monitoring(AppSettings(app_env="development"))

    assert called["value"] is False


def test_setup_error_monitoring_requires_dsn_outside_development() -> None:
    with pytest.raises(ValueError, match="SENTRY_DSN"):
        setup_error_monitoring(AppSettings(app_env="staging", sentry_dsn=None))


def test_setup_error_monitoring_initializes_sentry_for_staging(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    captured: dict[str, Any] = {}

    def fake_init(**kwargs: Any) -> None:
        captured.update(kwargs)

    monkeypatch.setattr("ssrq_editio.services.monitoring.sentry_sdk.init", fake_init)

    setup_error_monitoring(
        AppSettings(
            app_env="staging",
            sentry_dsn=SecretStr("https://abc@example.com/1"),
            release="test-release",
        )
    )

    assert captured["dsn"] == "https://abc@example.com/1"
    assert captured["environment"] == "staging"
    assert captured["release"] == "test-release"
    integration = captured["integrations"][0]
    assert integration._handler.level == logging.WARNING


def test_setup_error_monitoring_initializes_sentry_for_production(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    captured: dict[str, Any] = {}

    def fake_init(**kwargs: Any) -> None:
        captured.update(kwargs)

    monkeypatch.setattr("ssrq_editio.services.monitoring.sentry_sdk.init", fake_init)

    setup_error_monitoring(
        AppSettings(
            app_env="production",
            sentry_dsn=SecretStr("https://abc@example.com/1"),
            release="test-release",
        )
    )

    integration = captured["integrations"][0]
    assert integration._handler.level == logging.ERROR
