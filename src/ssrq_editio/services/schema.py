from os import getenv
from pathlib import Path

from ssrq_editio.adapters.file import load, load_via_http, write
from ssrq_editio.services.xslt.config import SCHEMA2TRANSLATIONS_XSL
from ssrq_editio.services.xslt.transformer import XSLTTransformationError, apply_xslt

SCHEMA_SRC = getenv("SCHEMA_SRC", "https://schema.ssrq-sds-fds.ch/dev/TEI_Schema.odd")


async def transpile_schema_to_translations(
    schema_src: str | Path,
    translations_dst: Path,
    xslt_script: Path = SCHEMA2TRANSLATIONS_XSL,
) -> Path:
    """A service to create a transpiled version of the SSRQ-XML-Schema.

    This minified version only contains the critical translation value, used for
    rendering TEI-XML-Files.

    Args:
        schema_src (str | Path): The source of the schema. If a source is provided as a Path object, the file_loader function
            will be used to load the file. Otherwise, the source is assumed to be a URL.
        translations_dst (Path): The destination of the translations.
        xslt_script (Path): The XSLT script to apply.

    Returns:
        The Path to the file containing the translations.

    Raises:
        ValueError: If the schema can't be converted to translations.
    """
    odd = (
        await load_via_http(schema_src)
        if isinstance(schema_src, str)
        else await load(schema_src.parent, schema_src.name)
    )
    result = await apply_xslt(
        (odd,), xslt_src_dir=xslt_script.parent.absolute(), xslt_script=xslt_script.name
    )

    if result[0].value is None:
        raise XSLTTransformationError(
            f"Failed to convert schema to translations; src: {schema_src}, xslt: {xslt_script}"
        )

    await write(translations_dst.parent, translations_dst.name, result[0].value)

    return translations_dst
