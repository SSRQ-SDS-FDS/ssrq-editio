from pathlib import Path
from cli.bundle.settings import read_build_config, read_docker_settings

PROJECT_ROOT = Path(__file__).parent.parent
EDITIO_CONFIG = PROJECT_ROOT / "editio_config.toml"
EXIST_APP_DIR = "eXist_app"
BUILD_CONFIG = read_build_config(EDITIO_CONFIG)
DOCKER_DEV_SETTINGS = read_docker_settings(EDITIO_CONFIG)
