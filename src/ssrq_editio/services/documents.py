import threading
from pathlib import Path
from typing import Self, Sequence, cast

from aiosqlite import Connection
from pydantic_core import from_json
from saxonche import PySaxonProcessor, PyXdmNode, PyXsltExecutable
from ssrq_utils.idno.model import IDNO
from ssrq_utils.lang.display import Lang
from ssrq_utils.uca import uca_simple_sort

from ssrq_editio.adapters.db.documents import get_document
from ssrq_editio.adapters.file import load
from ssrq_editio.models.documents import Document
from ssrq_editio.models.entities import EntityTypes, Places
from ssrq_editio.services.entities import get_entities
from ssrq_editio.services.xslt.transformer import (
    XSLTParam,
    XSLTTransformationError,
    apply_xslt,
    apply_xslt_in_parallel,
    compile_xslt,
)

DOCUMENT_INFO_XSLT = "document_info.xslt"
DOCUMENT_VIEW_XSLT = "document_view.xslt"


class DocumentTransformer:
    """Implemented as a singletion this class is reponsible for trasnforming
    the TEI-XML documents into their HTML representation.

    It makes use of the XSLT-services defined in `ssrq_editio.services.xslt.transformer`.
    Data and information snippets, which are shared between transformations, are
    stored inside this object. This is done to avoid reloading and speed up the
    overall processing time."""

    _instance: None | Self = None
    _lock: threading.Lock = threading.Lock()
    compiled_xslt: PyXsltExecutable
    ready_to_use: bool = False
    saxon_processor: PySaxonProcessor
    transpiled_schema: PyXdmNode
    xslt_src: str

    async def __call__(self):
        pass

    def __new__(cls, transpiled_schema: str, xslt_script: str = DOCUMENT_VIEW_XSLT) -> Self:
        """Creates a new instance of the DocumentTransformer class.

        Singleton pattern: If an instance already exists, it will be returned
        instead of creating a new one. Thread-safe. May not be used in
        multi-process environments.

        Args:
            transpiled_schema (str): The transpiled schema to use for the transformation.
            xslt_script (str, optional): The XSLT script to use for the transformation. Defaults to DOCUMENT_VIEW_XSLT.

        Returns:
            Self: The instance of the DocumentTransformer class.
        """
        if cls._instance is None:
            with cls._lock:
                cls._instance = super().__new__(cls)
                cls._instance.setup(xslt_script, transpiled_schema)
        return cls._instance

    def setup(
        self,
        xslt_script: str,
        transpiled_schema: str,
    ):
        self.xslt_script = xslt_script
        self._create_saxon_processor()
        self._get_schema_node(transpiled_schema)
        self.xslt_src = xslt_script

    async def ensure_xslt_is_prepared(self) -> None:
        """Ensures that the XSLT is compiled and ready to use."""
        if self.ready_to_use:
            return
        await self._prepare_xslt(self.xslt_src)
        self.ready_to_use = True

    def _create_saxon_processor(self) -> None | PySaxonProcessor:
        """Creates a Saxon processor without using
        a context manager. The Saxon processor object
        will live as long as the DocumentTransformer object
        does.

        Returns the Saxon processor object, when it's created,
        returns None if the processor already exists.

        Returns:
            None | PySaxonProcessor: The Saxon processor object.

        """
        if hasattr(self, "saxon_processor") and self.saxon_processor:
            return None
        self.saxon_processor = PySaxonProcessor(license=False)
        return self.saxon_processor

    async def _prepare_xslt(self, xslt_script: str):
        self.compiled_xslt = await compile_xslt(
            xslt_script=xslt_script,
            saxon_proc=self.saxon_processor,
            params=[XSLTParam("schema", self.transpiled_schema)],
        )

    def _get_schema_node(self, transpiled_schema: str):
        """Parses the transpiled schema and extract the TEI root element,
        which will be stored in the class as PyXdmNode.
        """
        xpath_processor = self.saxon_processor.new_xpath_processor()
        xpath_processor.set_context(
            xdm_item=self.saxon_processor.parse_xml(xml_text=transpiled_schema)
        )
        xpath_processor.declare_namespace(prefix="tei", uri="http://www.tei-c.org/ns/1.0")
        tei_root = xpath_processor.evaluate_single("/tei:TEI")

        if tei_root is None or not tei_root.is_node:
            raise ValueError("Could not find TEI root element in the transpiled schema.")

        self.transpiled_schema = tei_root.get_node_value()


async def extract_infos_from_xml(
    xml_src: tuple[Path, ...],
    volume_id: str,
    transpiled_schema: Path,
    xslt_script: str = DOCUMENT_INFO_XSLT,
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
            params=[
                XSLTParam("schema", transpiled_schema.as_uri()),
            ],
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
        Document.model_validate(_add_idno_info(from_json(doc.value), volume_id, doc.src))
        for doc in result
        if doc.value is not None
    )


async def find_and_load_xml_source(connection: Connection, doc_id: str):
    """Fetches information about a document from the database and loads the XML source.

    Args:
        connection (Connection): The SQLite connection.
        doc_id (str): The document ID.

    Returns:
        str: The loaded XML source.
    """
    doc_info = await get_document(connection, doc_id)

    if doc_info.source is None:
        raise ValueError(f"No source found for document with ID {doc_id}.")

    return await load(doc_info.source.parent, doc_info.source.name)


async def resolve_orig_places_for_documents(
    documents: Sequence[Document], connection: Connection, lang: Lang
) -> tuple[tuple[Document, Sequence[str] | None], ...]:
    """A service function to resolve the original places for the given documents.

    The resolved places will be sorted by their name (in the given language).

    ToDo: We should measure the performance here (maybe it could be good idea, if
    the get_entities function is cachable).

    Args:
        documents (Sequence[Document]): The documents to resolve the original places for.
        connection (Connection): The SQLite connection.
        lang (Lang): The language to sort the places by.

    Returns:
        tuple[tuple[Document, Sequence[str] | None], ...]: A tuple of document-place tuples.
    """
    places = cast(Places, await get_entities(connection, EntityTypes.PLACES))

    if len(places.entities) == 0:
        raise ValueError("No places found in the database for resolving.")

    return tuple(
        (
            document,
            uca_simple_sort(
                [
                    place.get_name_by_lang(lang)
                    for orig_place in document.orig_place
                    if (place := places.get_by_id(orig_place))
                ]
            )
            if document.orig_place
            else None,
        )
        for document in documents
    )


def _add_idno_info(document_info: dict, volume_id: str, source: Path | str) -> dict:
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
        "source": source,
    }
