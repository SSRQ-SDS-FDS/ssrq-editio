from pathlib import Path
from typing import Any, TypedDict, cast

from fastapi import Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from ssrq_utils.i18n.translator import Translator
from ssrq_utils.lang.display import Lang

from ssrq_editio.entrypoints.app.config import TRANSLATION_SOURCE
from ssrq_editio.entrypoints.app.setup import templates as TEMPLATES
from ssrq_editio.services.sort import UnicodeCollator


class ViewCoreData(TypedDict):
    page_description: str
    page_title: str


class ViewData(ViewCoreData, total=False):
    content: Any


class ViewContext(TypedDict):
    data: ViewData
    request: Request
    lang: Lang
    translator: Translator


class ViewModel:
    collator: UnicodeCollator
    lang: Lang
    request: Request
    page: str
    translator: Translator
    templates: Jinja2Templates

    def __init__(
        self,
        request: Request,
        lang: Lang,
        jinja_templates: Jinja2Templates = TEMPLATES,
        translation_source: Path = TRANSLATION_SOURCE,
    ):
        self.collator = UnicodeCollator()
        self.request = request
        self.templates = jinja_templates
        self.lang = lang
        self.translator = Translator(translation_source)

    async def create_context(self) -> ViewContext:
        raise NotImplementedError

    def error_to_html(self, error: Exception) -> HTMLResponse:
        return self.templates.TemplateResponse(
            "pages/error.jinja",
            {
                "data": {},
                "error": str(error),
                "lang": self.lang,
                "request": self.request,
                "translator": self.translator,
            },
            status_code=500,
        )

    async def to_html(self) -> HTMLResponse:
        try:
            return self.templates.TemplateResponse(
                f"pages/{self.page}", cast(dict, await self.create_context())
            )
        except Exception as error:
            return self.error_to_html(error)

    def _get_description(self) -> str:
        return self.translator.translate(self.lang, "title")

    def _get_title(self) -> str:
        raise NotImplementedError
