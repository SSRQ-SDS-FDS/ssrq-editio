from pathlib import Path
import shutil
from loguru import logger


def copy_misc_data(misc_source: Path, misc_target: Path) -> None:
    logger.info(f"Copying misc data files from {misc_source} to {misc_target}")
    shutil.copytree(misc_source, misc_target)
