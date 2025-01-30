from pathlib import Path

from pydantic_core import from_json
from ssrq_utils.idno.model import IDNO

from ssrq_editio.models.documents import Document
from ssrq_editio.services.xslt.transformer import (
    XSLTParam,
    XSLTTransformationError,
    apply_xslt,
    apply_xslt_in_parallel,
)


async def extract_infos_from_xml(
    xml_src: tuple[Path, ...],
    volume_id: str,
    transpiled_schema: Path,
    xslt_script: str = "document_info.xslt",
    parallel: bool = False,
) -> tuple[Document, ...]:
    """Extracts infos from the given TEI-XML sources for a specific volume.

    The information extraction is mainly done by applying an XSLT script, which
    reuses various logic implemented in the `ssrq-convert` package. The idno related
    processing is done by the `ssrq-utils` package.

    ToDo: Extract full-text from the XML sources.

    Args:
        xml_src (tuple[Path, ...]): The XML sources to extract infos from.
        volume_id (int): The volume id. Corresponds to the primary key of the volume.
        transpiled_schema (Path): The transpiled schema to use for the extraction.
        xslt_script (str, optional): The XSLT script to apply. Defaults to "document_info.xslt".
        parallel (bool, optional): Whether to apply the XSLT script in parallel. Defaults to False.

    Returns:
        tuple[Document, ...]: The extracted documents.

    Raises:
        XSLTTransformationError: If the extraction fails for any of the XML sources
    """
    result = (
        await apply_xslt(
            xml_src=xml_src,
            xslt_script=xslt_script,
            params=[XSLTParam("schema", transpiled_schema.as_uri())],
        )
        if not parallel
        else await apply_xslt_in_parallel(
            xml_src=xml_src,
            xslt_script=xslt_script,
            params=[XSLTParam("schema", transpiled_schema.as_uri())],
        )
    )

    if any(item is None for item in result):
        failed_items = [str(path) for path, item in zip(xml_src, result) if item is None]
        raise XSLTTransformationError(f"Could not extract infos from: {', '.join(failed_items)}")

    return tuple(
        map(
            lambda doc: Document.model_validate(_add_idno_info(from_json(doc), volume_id)),
            filter(None, result),
        )
    )


def _add_idno_info(document_info: dict, volume_id: str) -> dict:
    """Add additional information to the document info.

    Parses the idno and adds the following information:
    - is_main: Whether the idno is a main idno.
    - printed_idno: The idno as a string.
    - sort_key: A key to sort the documents by. Default: 99999.

    Args:
        document_info (dict): The document info.

    Returns:
        dict: The document info with additional information.
    """

    idno: str | None = document_info.get("idno")

    if idno is None:
        raise XSLTTransformationError(
            f"Seems the extraction failed to extract an idno for {document_info}."
        )

    parsed_idno = IDNO.model_validate_string(idno)

    return {
        **document_info,
        "is_main": parsed_idno.is_main(),
        "sort_key": parsed_idno.sort_key,
        "volume_id": volume_id,
    }
