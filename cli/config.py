from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
VOLUMES_CONFIG = PROJECT_ROOT / "volumes.toml"
VOLUMES_SOURCE = PROJECT_ROOT / "data/tei-volumes"
VOLUMES_TARGET = PROJECT_ROOT / "editio-data"
MISC_DATA_SOURCE = VOLUMES_SOURCE / "misc"
MISC_DATA_TARGET = VOLUMES_TARGET / "misc"
