from typing import Sequence

from aiosqlite import Connection
from fastapi import Request
from ssrq_utils.lang.display import Lang

from ssrq_editio.adapters.db.documents import get_document
from ssrq_editio.adapters.file import load
from ssrq_editio.entrypoints.app.views.models.base import ViewContext, ViewModel
from ssrq_editio.models.documents import Document, DocumentDisplay
from ssrq_editio.models.kantons import KantonName
from ssrq_editio.models.volumes import Volume
from ssrq_editio.services.documents import (
    DocumentTransformer,
    create_idno_from_volume_and_doc_number,
    resolve_orig_places_for_documents,
)
from ssrq_editio.services.volumes import get_volume_info


class DocumentViewModel(ViewModel):
    """This View Model is used to display documents."""

    connection: Connection
    document: str
    document_info: Document
    kanton: KantonName
    orig_places: Sequence[str] | None
    transformer: DocumentTransformer
    volume: str
    volume_info: Volume

    def __init__(
        self,
        request: Request,
        lang: Lang,
        connection: Connection,
        kanton: KantonName,
        volume: str,
        document: str,
        transformer: DocumentTransformer,
    ):
        super().__init__(request, lang)
        self.page = "document.jinja"
        self.connection = connection
        self.kanton = kanton
        self.volume = volume
        self.document = document
        self.transformer = transformer

    async def create_context(self) -> ViewContext:
        await self._get_volume_info()
        await self._get_document()

        return ViewContext(
            request=self.request,
            lang=self.lang,
            data={
                "page_title": self._get_title(),
                "page_description": self._get_description(),
                "content": {
                    "kanton": self.kanton.value,
                    "volume": self.volume_info,
                    "doc": self.document_info,
                    "orig_places": self.orig_places,
                    "rendered_doc": await self._transform_document(),
                },
            },
            translator=self.translator,
        )

    async def _get_volume_info(self):
        self.volume_info = await get_volume_info(self.connection, self.kanton, self.volume)

    def _get_title(self) -> str:
        return f"{self.translator.translate(self.lang, 'short_title')} · {self.document_info.printed_idno}"

    async def _get_document(self):
        result = await get_document(
            self.connection, create_idno_from_volume_and_doc_number(self.volume_info, self.document)
        )

        self.document_info = result

        _, orig_places = (
            await resolve_orig_places_for_documents((result,), self.connection, self.lang)
        )[0]

        self.orig_places = orig_places

    async def _transform_document(self) -> DocumentDisplay:
        if self.document_info.source is None:
            raise ValueError(
                f"Can't create HTML-View for {self.document_info.uuid}, no source file provided."
            )
        source = await load(self.document_info.source.parent, self.document_info.source.name)
        return self.transformer(xml_src=source, output_lang=self.lang)
