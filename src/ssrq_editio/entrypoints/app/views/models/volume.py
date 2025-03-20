from typing import Sequence, override

from aiosqlite import Connection
from fastapi import Request
from ssrq_utils.lang.display import Lang

from ssrq_editio.adapters.db.documents import get_documents
from ssrq_editio.adapters.db.volumes import check_facsimiles
from ssrq_editio.entrypoints.app.views.models.base import ViewContext, ViewModel
from ssrq_editio.models.documents import Document
from ssrq_editio.models.kantons import KantonName
from ssrq_editio.models.volumes import Volume
from ssrq_editio.services.documents import resolve_orig_places_for_documents
from ssrq_editio.services.paginate import create_pages
from ssrq_editio.services.volumes import get_volume_info


class VolumeViewModel(ViewModel):
    """This View Model is used to display a list of documents per volume."""

    connection: Connection
    kanton: KantonName
    volume: str
    query: str | None
    facs: bool
    current_page: int
    per_page: int
    volume_info: Volume | None = None

    def __init__(
        self,
        request: Request,
        lang: Lang,
        connection: Connection,
        kanton: KantonName,
        volume: str,
        query: str | None,
        facs: bool,
        page: int,
        per_page: int,
    ):
        super().__init__(request, lang)
        self.page = "document_list.jinja"
        self.template_partial = "documents"
        self.connection = connection
        self.kanton = kanton
        self.volume = volume
        self.query = query
        self.facs = facs
        self.current_page = page
        self.per_page = per_page

    @property
    def volume_id(self) -> str:
        return f"{self.kanton.value}_{self.volume}"

    async def create_context(self) -> ViewContext:
        # search_result = await self._get_entities()
        if self.volume_info is None:
            self.volume_info = await get_volume_info(self.connection, self.kanton, self.volume)

        show_facs = await check_facsimiles(self.connection, self.volume_id)

        if show_facs is False and self.facs:
            # Handles the edge case when a url was manually entered
            self.facs = False

        search_result = await self._get_documents()

        return ViewContext(
            request=self.request,
            lang=self.lang,
            data={
                "page_title": self._get_title(),
                "page_description": self._get_description(),
                "content": {
                    "current_page": self.current_page,
                    "documents": search_result[1][0] if search_result else None,
                    "facs": self.facs,
                    "kanton": self.kanton.value,
                    "pages": search_result[1][1] if search_result else None,
                    "show_facs": show_facs,
                    "query": self.query,
                    "total": search_result[0] if search_result else None,
                    "volume": self.volume_info,
                },
            },
            translator=self.translator,
        )

    @override
    def _get_title(self) -> str:
        return f"{self.translator.translate(self.lang, 'short_title')} · {self.kanton.value} {self.volume_info.name if self.volume_info else self.volume}"

    async def _get_documents(
        self,
    ) -> (
        None
        | tuple[int, tuple[tuple[tuple[Document, Sequence[str] | None], ...], list[int] | None]]
    ):
        result = await get_documents(
            connection=self.connection,
            volume_id=self.volume_id,
            search=self.query,
            facs=self.facs,
        )

        total_hits = len(result)

        if total_hits == 0:
            return None

        paged_documents = create_pages(
            result,
            self.current_page,
            self.per_page,
        )

        return total_hits, (
            await resolve_orig_places_for_documents(paged_documents[0], self.connection, self.lang),
            paged_documents[1],
        )
