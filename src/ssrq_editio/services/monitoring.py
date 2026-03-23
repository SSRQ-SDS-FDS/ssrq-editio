import logging
from typing import Literal, Optional

import sentry_sdk
from pydantic import SecretStr
from pydantic_settings import BaseSettings
from sentry_sdk.integrations.logging import LoggingIntegration

from ssrq_editio.entrypoints.app.shared.version import get_display_version

Env = Literal["development", "staging", "production"]


class Monitoring_Settings(BaseSettings):
    """Load monitoring settings from environment.
    Source priority: process ENV > .env > class defaults

    Variables:
      - APP_ENV
      - RELEASE
      - SENTRY_DSN
    """

    app_env: Env = "development"
    release: Optional[str] = get_display_version()
    sentry_dsn: Optional[SecretStr] = None

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "extra": "ignore",
    }


def setup_error_monitoring(cfg: Monitoring_Settings) -> None:
    """Configure Sentry/GlitchTip error monitoring for 'staging' and 'production'.

    - No tracking in 'development'.
    - Sets Sentry environment and release from 'cfg'.
    - Captures logging events at WARNING and above in 'staging',
      and at ERROR and above in other non-development environments.

    Args:
        cfg (Monitoring_Settings):
            - app_env (str): ['development', 'staging', 'production']
            - sentry_dsn (SecretStr | str): Sentry/GlitchTip DSN
            - release (str): Application release identifier
    """
    if cfg.app_env == "development":
        return
    else:
        if not cfg.sentry_dsn:
            raise Exception("DSN not set.")
        sentry_sdk.init(
            dsn=cfg.sentry_dsn.get_secret_value(),
            environment=cfg.app_env,
            release=cfg.release,
            integrations=[
                LoggingIntegration(
                    event_level=logging.WARNING if cfg.app_env == "staging" else logging.ERROR,
                ),
            ],
        )
