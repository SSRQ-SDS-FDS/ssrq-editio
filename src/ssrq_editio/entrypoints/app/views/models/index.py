from fastapi import Request
from ssrq_editio.entrypoints.app.views.models.base import ViewModel
from ssrq_utils.lang.display import Lang
from .base import ViewContext


class IndexViewModel(ViewModel):
    def __init__(self, request: Request, lang: Lang):
        super().__init__(request, lang)
        self.page = "index.jinja"

    async def create_context(self) -> ViewContext:
        return ViewContext(request=self.request, lang=self.lang, data={})
