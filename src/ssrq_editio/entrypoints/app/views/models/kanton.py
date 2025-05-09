from aiosqlite import Connection
from fastapi import Request
from ssrq_utils.lang.display import Lang

from ssrq_editio.adapters.db.volumes import list_volumes_with_editors
from ssrq_editio.entrypoints.app.views.models.base import ViewModel

from .base import ViewContext


class KantonViewModel(ViewModel):
    """This View Model is used to display the list of volumes per kanton."""

    connection: Connection
    kanton: str

    def __init__(self, request: Request, lang: Lang, connection: Connection, kanton: str):
        super().__init__(request, lang)
        self.page = "kanton.jinja"
        self.connection = connection
        self.kanton = kanton

    async def create_context(self) -> ViewContext:
        volumes = await list_volumes_with_editors(self.connection, self.kanton)

        if volumes is None:
            raise ValueError(f"No data available for »{self.kanton}«.")

        return ViewContext(
            request=self.request,
            lang=self.lang,
            data={
                "page_title": self._get_title(),
                "page_description": self._get_description(),
                "content": volumes,
            },
            translator=self.translator,
        )

    def _get_title(self) -> str:
        return f"{self.translator.translate(self.lang, 'short_title')} · {self.kanton}"
