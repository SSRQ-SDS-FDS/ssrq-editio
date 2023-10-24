from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
EDITIO_CONFIG = PROJECT_ROOT / "editio_config.toml"
VOLUMES_SOURCE = PROJECT_ROOT / "data/tei-volumes"
VOLUMES_TARGET = PROJECT_ROOT / "editio-data"
MISC_DATA_SOURCE = VOLUMES_SOURCE / "misc"
MISC_DATA_TARGET = VOLUMES_TARGET / "misc"
SASS_SOURCE = PROJECT_ROOT / "resources/scss/style.scss"
CSS_TARGET = PROJECT_ROOT / "resources/css/style.css"
EXPATH_PKG = PROJECT_ROOT / "expath-pkg.xml"

# list of files and folders to ignore when building the application
COMMON_IGNORES = [
    ".DS_Store",
    ".git",
    "build.xml",
    ".existdb.json",
    "editio_config.toml",
    "pyproject.toml",
    "poetry.lock",
    "README.md",
    "build",
    "cli",
    "data",
    "resources/scss",
    "transform",
]
PROD_IGNORES = COMMON_IGNORES + [
    "test",
    "modules/lib/regenerate.xql",
    "modules/pub/upload.xql",
    "templates/upload.html",
    "routes/temp.html",
]


# Configs for docker
DEV_COMPOSE_FILE = PROJECT_ROOT / "docker-compose.dev.yml"
DEV_DUMMY_PASSWORD = "ssrq"
EDITIO_PORT = "8080"
