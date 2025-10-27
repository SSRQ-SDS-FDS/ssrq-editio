from fastapi import Request
from ssrq_utils.lang.display import Lang

from ssrq_editio.entrypoints.app.views.models.base import ViewModel

from .base import ViewContext


class ErrorViewModel(ViewModel):
    def __init__(self, request: Request, lang: Lang, status_code: int):
        super().__init__(request, lang)
        self.page = "error.jinja"
        self.status_code = status_code

    async def create_context(self) -> ViewContext:
        return ViewContext(
            request=self.request,
            lang=self.lang,
            data={
                "page_title": self._get_title(),
                "page_description": self._get_description(),
                "content": {},
            },
            translator=self.translator,
        )

    def _get_title(self) -> str:
        return self.translator.translate(self.lang, "short_title")
