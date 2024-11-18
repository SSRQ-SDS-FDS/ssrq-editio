from pathlib import Path
from typing import Any, TypedDict, cast
from fastapi import Request
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse
from ssrq_editio.entrypoints.app.setup import templates as TEMPLATES
from ssrq_utils.lang.display import Lang
from ssrq_utils.i18n.translator import Translator
from ssrq_editio.entrypoints.app.config import TRANSLATION_SOURCE


class ViewContext(TypedDict):
    data: dict[str, Any]
    request: Request
    lang: Lang


class ViewModel:
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
        self.request = request
        self.templates = jinja_templates
        self.lang = lang
        self.translator = Translator(translation_source)

    async def to_html(self) -> HTMLResponse:
        return self.templates.TemplateResponse(
            f"pages/{self.page}", cast(dict, await self.create_context())
        )

    async def create_context(self) -> ViewContext:
        raise NotImplementedError
