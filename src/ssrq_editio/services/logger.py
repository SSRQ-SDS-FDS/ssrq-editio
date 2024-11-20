import sys

from loguru import logger

__all__ = ["SSRQ_LOGGER"]


def _configure_logger():
    """Configures a simple logging service.

    This logger should not be used for production purposes or
    as part of the webapp. It is only uzsed for debugging or
    as part of the CLI.

    Returns:
        Logger: The configured logger.
    """
    logger.remove()
    logger.add(
        sys.stdout,
        format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level}</level> | <level>{message}</level>",
        colorize=True,
    )
    logger.level("DEBUG")
    return logger


SSRQ_LOGGER = _configure_logger()
