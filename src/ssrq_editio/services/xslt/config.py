from pathlib import Path

XSLT_SRC_DIR = Path(__file__).parent / "scripts"
SCHEMA2TRANSLATIONS_XSL = (
    XSLT_SRC_DIR / "convert/src/ssrq_convert/tei2pub/xsl/schema2translations.xsl"
)
TEI2PUB_XSL = XSLT_SRC_DIR / "convert/src/ssrq_convert/tei2pub/xsl/tei2pub.xsl"
