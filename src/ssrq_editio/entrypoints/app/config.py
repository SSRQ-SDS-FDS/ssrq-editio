from pathlib import Path

CONTEXT = Path(__file__).parent
ASSET_DIR = CONTEXT / "static"
TEMPLATE_DIR = CONTEXT / "views"
COMPONENT_DIR = TEMPLATE_DIR / "components"
TRANSLATION_SOURCE = ASSET_DIR / "i18n" / "translations.json"
