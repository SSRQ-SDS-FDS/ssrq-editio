from pathlib import Path

from pydantic_core import from_json
from ssrq_utils.idno.filter import idno_is_main
from ssrq_utils.idno.model import IDNO

from ssrq_editio.models.documents import Document
from ssrq_editio.services.xslt.transformer import XSLTParam, XSLTTransformationError, apply_xslt


async def extract_infos_from_xml(
    xml_src: tuple[Path, ...],
    volume_id: int,
    transpiled_schema: Path,
    xslt_script: str = "document_info.xslt",
) -> tuple[Document, ...]:
    result = await apply_xslt(
        xml_src=xml_src,
        xslt_script=xslt_script,
        params=[XSLTParam("schema", transpiled_schema.as_uri())],
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


def _add_idno_info(document_info: dict, volume_id: int) -> dict:
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
        "is_main": idno_is_main(parsed_idno),
        "sort_key": next(filter(None, (parsed_idno.case, parsed_idno.doc, 99999))),
        "volume_id": volume_id,
    }
