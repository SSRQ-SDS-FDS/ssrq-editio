from typing import Sequence, override

from aiosqlite import Connection
from fastapi import Request
from ssrq_utils.lang.display import Lang

from ssrq_editio.adapters.db.documents import get_documents
from ssrq_editio.adapters.db.volumes import retrieve_volume_metadata
from ssrq_editio.entrypoints.app.views.models.base import ViewContext, ViewModel
from ssrq_editio.models.documents import Document, DocumentType
from ssrq_editio.models.kantons import KantonName
from ssrq_editio.models.volumes import Volume, VolumeMeta
from ssrq_editio.services.documents import resolve_orig_places_for_documents
from ssrq_editio.services.paginate import create_pages, get_valid_page_number
from ssrq_editio.services.volumes import get_volume_info


class VolumeViewModel(ViewModel):
    """This View Model is used to display a list of documents per volume."""

    connection: Connection
    kanton: KantonName
    volume: str
    query: str | None
    facs: bool
    doc_type: DocumentType | None
    current_page: int
    per_page: int
    volume_info: Volume | None = None
    range_start: int | None = None
    range_end: int | None = None

    def __init__(
        self,
        request: Request,
        lang: Lang,
        connection: Connection,
        kanton: KantonName,
        volume: str,
        query: str | None,
        facs: bool,
        doc_type: DocumentType | None,
        page: int,
        per_page: int,
        range_start: int | None,
        range_end: int | None,
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
        self.doc_type = doc_type
        self.range_start = range_start
        self.range_end = range_end

    @property
    def volume_id(self) -> str:
        return f"{self.kanton.value}_{self.volume}"

    def compute_range(self, range_value: int | None, volume_meta: VolumeMeta) -> int | None:
        """Computes the range value(s) for the documents list.

        This helper method will ensure, that we will not apply the
        range filters, when they are equal to the first and last year even
         if the request passed the parameters. This may be the case, when
        HTMX triggered the request and the user just did a reset of the range
        by using the slider.

        Args:
            range_value (int | None): The range value to compute.
            volume_meta (VolumeMeta): The metadata for the volume.

        Returns:
            int | None: The computed range value or None if the
            range value is None.
        """

        if range_value is None:
            return range_value

        if volume_meta.first_year is None and volume_meta.last_year is None:
            return None

        if self.range_start == volume_meta.first_year and self.range_end == volume_meta.last_year:
            return None

        return range_value

    async def create_context(self) -> ViewContext:
        if self.volume_info is None:
            self.volume_info = await get_volume_info(self.connection, self.kanton, self.volume)

        vol_meta = await retrieve_volume_metadata(self.connection, self.volume_id)

        if vol_meta.has_facs is False and self.facs:
            # Handles the edge case when a url was manually entered
            self.facs = False

        search_result = await self._get_documents(vol_meta)

        return ViewContext(
            request=self.request,
            lang=self.lang,
            data={
                "page_title": self._get_title(),
                "page_description": self._get_description(),
                "content": {
                    "current_page": self.current_page,
                    "documents": search_result[1][0] if search_result else None,
                    "document_type": self.doc_type,
                    "document_types": vol_meta.document_types,
                    "facs": self.facs,
                    "first_year": vol_meta.first_year,
                    "kanton": self.kanton.value,
                    "last_year": vol_meta.last_year,
                    "pages": search_result[1][1] if search_result else None,
                    "range_start": self.range_start or vol_meta.first_year,
                    "range_end": self.range_end or vol_meta.last_year,
                    "show_facs": vol_meta.has_facs,
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
        self, vol_meta: VolumeMeta
    ) -> (
        None
        | tuple[int, tuple[tuple[tuple[Document, Sequence[str] | None], ...], list[int] | None]]
    ):
        result = await get_documents(
            connection=self.connection,
            volume_id=self.volume_id,
            search=self.query,
            facs=self.facs,
            doc_type=self.doc_type,
            range_start=self.compute_range(self.range_start, vol_meta),
            range_end=self.compute_range(self.range_end, vol_meta),
        )

        total_hits = len(result)

        if total_hits == 0:
            return None

        self.current_page = get_valid_page_number(
            current_page=self.current_page, per_page=self.per_page, total_hits=total_hits
        )
        paged_documents = create_pages(
            result,
            self.current_page,
            self.per_page,
        )

        return total_hits, (
            await resolve_orig_places_for_documents(paged_documents[0], self.connection, self.lang),
            paged_documents[1],
        )
