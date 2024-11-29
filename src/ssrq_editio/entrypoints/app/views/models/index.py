from aiosqlite import Connection
from fastapi import Request
from ssrq_utils.lang.display import Lang

from ssrq_editio.adapters.db.kantons import list_kantons
from ssrq_editio.entrypoints.app.views.models.base import ViewModel

from .base import ViewContext


class IndexViewModel(ViewModel):
    connection: Connection

    def __init__(self, request: Request, lang: Lang, connection: Connection):
        super().__init__(request, lang)
        self.page = "index.jinja"
        self.connection = connection

    async def create_context(self) -> ViewContext:
        kantons = await list_kantons(self.connection)
        return ViewContext(
            request=self.request,
            lang=self.lang,
            data={
                "page_title": self._get_title(),
                "page_description": self._get_description(),
                "content": kantons,
            },
            translator=self.translator,
        )

    def _get_title(self) -> str:
        return self.translator.translate(self.lang, "short_title")
