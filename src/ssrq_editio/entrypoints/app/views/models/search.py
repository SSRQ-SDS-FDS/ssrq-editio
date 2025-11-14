from typing import Sequence

from aiosqlite import Connection
from fastapi import Request
from ssrq_utils.lang.display import Lang

from ssrq_editio.adapters.db.documents import get_documents_by_ft
from ssrq_editio.entrypoints.app.views.models.base import ViewContext, ViewModel
from ssrq_editio.models.documents import DocumentFulltextResult
from ssrq_editio.services.paginate import create_pages, get_valid_page_number


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
    ):
        super().__init__(request, lang)
        self.page = "search.jinja"
        self.template_partial = "documents"
        self.connection = connection
        self.query = query
        self.current_page = current_page
        self.per_page = per_page

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
                },
            },
            translator=self.translator,
        )

    def _get_title(self) -> str:
        return f"{self.translator.translate(self.lang, 'short_title')} · {self.translator.translate(self.lang, 'search')}"

    async def _get_documents_by_ft_search(
        self,
    ) -> None | tuple[int, tuple[Sequence[DocumentFulltextResult], list[int] | None]]:
        results = await get_documents_by_ft(connection=self.connection, search=self.query)
        total_hits = len(results)

        if total_hits == 0:
            return None

        self.current_page = get_valid_page_number(
            current_page=self.current_page, per_page=self.per_page, total_hits=total_hits
        )
        paged_results = create_pages(
            items=results,
            current_page=self.current_page,
            per_page=self.per_page,
        )

        return total_hits, paged_results
