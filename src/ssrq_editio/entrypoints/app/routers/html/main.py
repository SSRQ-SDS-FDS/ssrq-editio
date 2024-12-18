from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse, RedirectResponse

from ssrq_editio.entrypoints.app.routers.api import api
from ssrq_editio.entrypoints.app.shared.dependencies import DBDependency, LangDependency
from ssrq_editio.entrypoints.app.views.models.entity import EntityViewModel
from ssrq_editio.entrypoints.app.views.models.index import IndexViewModel
from ssrq_editio.entrypoints.app.views.models.kanton import KantonViewModel
from ssrq_editio.models.entities import EntityTypes
from ssrq_editio.models.kantons import KantonName

html = APIRouter(default_response_class=HTMLResponse, include_in_schema=False)


@html.get("/")
async def index(request: Request, lang: LangDependency, connection: DBDependency):
    return await IndexViewModel(request, lang, connection).to_html()


# Routes, which are direct child of the root must be placed before such routes,
# which use path parametzers
@html.get("/search", name="search")
async def search(request: Request, lang: LangDependency, query: str | None):
    raise NotImplementedError


@html.get("/index", name="entities")
async def entities(request: Request):
    """Redirect all requests to the main index page, to
    the subpage, which lists all keywords."""
    return RedirectResponse(html.url_path_for("entity_view", entity_type="keywords"))


@html.get("/about/digital-edition", name="info_edition")
async def scholarly_information(request: Request, lang: LangDependency):
    raise NotImplementedError


@html.get("/about/partners-and-funding", name="partners_and_funding")
async def partners_and_funding(request: Request, lang: LangDependency):
    raise NotImplementedError


@html.get("/about/tech", name="tech")
async def tech_docs(request: Request, lang: LangDependency):
    raise NotImplementedError


@html.get("/index/{entity_type}", name="entity_view")
async def list_entities(
    request: Request,
    lang: LangDependency,
    connection: DBDependency,
    entity_type: EntityTypes,
    query: str | None = None,
    page: int = 1,
    per_page: int = 25,
):
    return await EntityViewModel(
        request, lang, connection, entity_type, query, page, per_page
    ).to_html()


@html.get("/{kanton}", name="kanton")
async def volumes(
    kanton: KantonName, request: Request, lang: LangDependency, connection: DBDependency
):
    return await KantonViewModel(request, lang, connection, str(kanton)).to_html()


@html.get("/{kanton}/{volume}.pdf", name="volume_pdf")
async def volume_pdf(
    kanton: KantonName,
    volume: str,
):
    return RedirectResponse(api.url_path_for("api_v1_volume_pdf", kanton=kanton, volume=volume))


@html.get("/{kanton}/{volume}", name="document_list")
async def documents(
    kanton: KantonName,
    volume: str,
    request: Request,
    lang: LangDependency,
    connection: DBDependency,
):
    print("this will be shown now! documents...")
    return f"{kanton} {volume}"


@html.get("/{kanton}/{volume}/{document}", name="document_view")
async def document(
    kanton: KantonName,
    volume: str,
    document: str,
    request: Request,
    lang: LangDependency,
    connection: DBDependency,
):
    raise NotImplementedError
