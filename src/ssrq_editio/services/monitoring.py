import logging

import sentry_sdk
from sentry_sdk.integrations.logging import LoggingIntegration

from ssrq_editio.entrypoints.app.settings import AppSettings
from ssrq_editio.entrypoints.app.shared.version import get_display_version


def setup_error_monitoring(cfg: AppSettings) -> None:
    """Configure Sentry/GlitchTip error monitoring for 'staging' and 'production'.

    - No tracking in 'development'.
    - Sets Sentry environment and release from 'cfg'.
    - Captures logging events at WARNING and above in 'staging',
      and at ERROR and above in other non-development environments.

    Args:
        cfg (AppSettings):
            - app_env (str): ['development', 'staging', 'production']
            - sentry_dsn (SecretStr | str): Sentry/GlitchTip DSN
            - release (str): Application release identifier
    """
    if cfg.app_env == "development":
        return

    if not cfg.sentry_dsn:
        raise ValueError("SENTRY_DSN is required when APP_ENV is not 'development'.")

    sentry_sdk.init(
        dsn=cfg.sentry_dsn.get_secret_value(),
        environment=cfg.app_env,
        release=cfg.release or get_display_version(),
        integrations=[
            LoggingIntegration(
                event_level=logging.WARNING if cfg.app_env == "staging" else logging.ERROR,
            ),
        ],
    )
