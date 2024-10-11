from typing import Any, TypedDict, cast
from fastapi import Request
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse
from ssrq_editio.entrypoints.app.setup import templates as TEMPLATES
from ssrq_editio.models.lang import Lang


class ViewContext(TypedDict):
    data: dict[str, Any]
    request: Request
    lang: Lang


class ViewModel:
    lang: Lang
    request: Request
    page: str
    templates: Jinja2Templates

    def __init__(self, request: Request, lang: Lang, jinja_templates: Jinja2Templates = TEMPLATES):
        self.request = request
        self.templates = jinja_templates
        self.lang = lang

    async def to_html(self) -> HTMLResponse:
        return self.templates.TemplateResponse(
            f"pages/{self.page}", cast(dict, await self.create_context())
        )

    async def create_context(self) -> ViewContext:
        raise NotImplementedError
