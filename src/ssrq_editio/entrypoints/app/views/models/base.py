import os
from pathlib import Path
from typing import Any, TypedDict, cast

import cachebox
from fastapi import Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from ssrq_utils.i18n.translator import Translator
from ssrq_utils.lang.display import Lang

from ssrq_editio.entrypoints.app.config import TRANSLATION_SOURCE
from ssrq_editio.entrypoints.app.setup import templates as TEMPLATES


def _load_int_env(name: str, fallback: int, minimum: int) -> int:
    value = os.getenv(name)

    if value is None:
        return fallback

    try:
        return max(int(value), minimum)
    except ValueError:
        return fallback


VIEW_CACHE_MAXSIZE = _load_int_env("EDITIO_VIEW_CACHE_MAXSIZE", fallback=128, minimum=1)
VIEW_CACHE_TTL_SECONDS = _load_int_env("EDITIO_VIEW_CACHE_TTL_SECONDS", fallback=900, minimum=1)
VIEW_RESPONSE_CACHE: cachebox.TTLCache = cachebox.TTLCache(
    maxsize=VIEW_CACHE_MAXSIZE, ttl=VIEW_CACHE_TTL_SECONDS
)


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
    css: set[str] = {"fonts/font.css", "css/dist/style.css"}
    js: set[str] = {"js/dist/app/app.js"}
    lang: Lang
    request: Request
    page: str
    template_partial: str | None = None
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

    def add_css(self, name: str):
        """Add a additional (view specific) CSS file to the model.

        Args:
            name (str): The name of the CSS file to add.

        Returns:
            None
        """
        self.css.add(name)

    def add_js(self, name: str):
        """Add a additional (view specific) JS file to the model.

        Args:
            name (str): The name of the JS file to add.

        Returns:
            None
        """
        self.js.add(name)

    async def create_context(self) -> ViewContext:
        raise NotImplementedError

    def put_assets_in_context(self, context: dict[str, Any]) -> None:
        """Put the assets (CSS and JS) into the context.

        Args:
            context (dict[str, Any]): The context to put the assets in.

        Returns:
            None
        """
        context["css"] = self.css
        context["js"] = self.js

    def error_to_html(self, error: Exception) -> HTMLResponse:
        context = {
            "data": {},
            "error": str(error),
            "lang": self.lang,
            "request": self.request,
            "translator": self.translator,
        }
        self.put_assets_in_context(context)
        return self.templates.TemplateResponse(
            request=self.request,
            name="pages/error.jinja",
            context=context,
            status_code=500,
        )

    async def to_html(self) -> HTMLResponse:
        return await serve_html_response(self)

    async def _to_html(self) -> HTMLResponse:
        try:
            context = cast(dict, await self.create_context())
            self.put_assets_in_context(context)
            page_template = f"pages/{self.page}"

            # If the request is an htmx request and a partial template is set,
            # we will return the partial template instead of the full page.
            if self._is_htmx_request() and self.template_partial:
                return self.templates.TemplateResponse(
                    request=self.request,
                    name=page_template,
                    context=context,
                    block_name=self.template_partial,
                )  # type: ignore
            return self.templates.TemplateResponse(
                request=self.request, name=f"pages/{self.page}", context=context
            )
        except Exception as error:
            return self.error_to_html(error)

    def _is_htmx_request(self) -> bool:
        return bool(self.request.headers.get("HX-Request"))

    def _get_description(self) -> str:
        return self.translator.translate(self.lang, "title")

    def _get_title(self) -> str:
        raise NotImplementedError


def _calculate_cache_key(args, kwargs) -> str:
    view: ViewModel = args[0]
    return f"{view.request.url._url}_{view.lang.value}_{view.request.method}_{view.request.headers.get('HX-Request', '')}"


async def serve_html_response(view: ViewModel) -> HTMLResponse:
    """A helper function to serve the HTML response from the view model.

    It will cache the responses on a global bases in memory, which
    should speed up the response time for the same request.

    Args:
        view (ViewModel): The view model instance.

    Returns:
        HTMLResponse: The HTML response.
    """
    if view.request.method != "GET":
        return await view._to_html()

    VIEW_RESPONSE_CACHE.expire()
    cache_key = _calculate_cache_key((view,), {})
    cached_html = VIEW_RESPONSE_CACHE.get(cache_key)

    if cached_html is not None:
        return HTMLResponse(content=cached_html)

    response = await view._to_html()

    # Only cache successful responses to avoid persisting transient errors.
    if response.status_code == 200:
        VIEW_RESPONSE_CACHE[cache_key] = response.body

    return response
