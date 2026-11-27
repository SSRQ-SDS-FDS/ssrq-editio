from typing import Sequence

from aiosqlite import Connection
from fastapi import Request
from ssrq_utils.lang.display import Lang

from ssrq_editio.entrypoints.app.views.models.base import ViewContext, ViewModel
from ssrq_editio.models.documents import Document
from ssrq_editio.models.search import SearchArea, SearchFilter, SearchFilterOption
from ssrq_editio.services.documents import resolve_orig_places_for_documents
from ssrq_editio.services.paginate import create_pages, get_valid_page_number
from ssrq_editio.services.search import find_documents


class SearchViewModel(ViewModel):
    """This View Model is used to display the results of the ft-search."""

    connection: Connection
    document: str
    query: str | None
    current_page: int
    per_page: int

    def __init__(
        self,
        request: Request,
        lang: Lang,
        connection: Connection,
        query: str | None,
        current_page: int,
        per_page: int,
        areas: tuple[SearchArea, ...] = tuple(SearchArea),
    ):
        super().__init__(request, lang)
        self.page = "search.jinja"
        self.template_partial = "documents"
        self.connection = connection
        self.query = query
        self.current_page = current_page
        self.per_page = per_page
        self.areas = areas

    async def create_context(self) -> ViewContext:
        search_result = await self._get_documents_by_ft_search()

        return ViewContext(
            request=self.request,
            lang=self.lang,
            data={
                "page_title": self._get_title(),
                "page_description": self._get_description(),
                "content": {
                    "current_page": self.current_page,
                    "pages": search_result[1][1] if search_result else None,
                    "query": self.query,
                    "results": search_result[1][0] if search_result else None,
                    "total": search_result[0] if search_result else None,
                    "filters": [self._create_area_filter().model_dump()],
                },
            },
            translator=self.translator,
        )

    def _create_area_filter(self) -> SearchFilter:
        """Create the search-area filter from the current selection."""
        return SearchFilter(
            name="area",
            options=[
                SearchFilterOption(value=area.value, selected=area in self.areas)
                for area in SearchArea
            ],
        )

    def _get_title(self) -> str:
        return f"{self.translator.translate(self.lang, 'short_title')} · {self.translator.translate(self.lang, 'search')}"

    async def _get_documents_by_ft_search(
        self,
    ) -> (
        None
        | tuple[int, tuple[tuple[tuple[Document, Sequence[str] | None], ...], list[int] | None]]
    ):
        """Load shared search results and apply pagination for the web presentation."""
        search_results = await find_documents(
            connection=self.connection, query=self.query, areas=self.areas
        )
        total = len(search_results)

        if total == 0:
            return None

        self.current_page = get_valid_page_number(
            current_page=self.current_page,
            per_page=self.per_page,
            total_hits=total,
        )
        documents, pages = create_pages(
            items=search_results,
            current_page=self.current_page,
            per_page=self.per_page,
        )

        resolved_documents = await resolve_orig_places_for_documents(
            documents, self.connection, self.lang
        )

        return total, (resolved_documents, pages)
