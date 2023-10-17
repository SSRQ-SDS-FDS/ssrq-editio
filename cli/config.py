from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
EDITIO_CONFIG = PROJECT_ROOT / "editio_config.toml"
VOLUMES_SOURCE = PROJECT_ROOT / "data/tei-volumes"
VOLUMES_TARGET = PROJECT_ROOT / "editio-data"
MISC_DATA_SOURCE = VOLUMES_SOURCE / "misc"
MISC_DATA_TARGET = VOLUMES_TARGET / "misc"
SASS_SOURCE = PROJECT_ROOT / "resources/scss/style.scss"
CSS_TARGET = PROJECT_ROOT / "resources/css/style.css"
