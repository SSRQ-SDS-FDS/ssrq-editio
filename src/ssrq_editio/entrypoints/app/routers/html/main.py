from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse, RedirectResponse

from ssrq_editio.entrypoints.app.routers.api import api
from ssrq_editio.entrypoints.app.shared.dependencies import DBDependency, LangDependency
from ssrq_editio.entrypoints.app.views.models.index import IndexViewModel
from ssrq_editio.entrypoints.app.views.models.kanton import KantonViewModel
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


@html.get("/{kanton}", name="kanton")
async def volumes(
    kanton: KantonName, request: Request, lang: LangDependency, connection: DBDependency
):
    return await KantonViewModel(request, lang, connection, str(kanton)).to_html()


@html.get("/{kanton}/{volume}.pdf", name="volume_pdf")
async def volume_pdf(
    kanton: str,
    volume: str,
):
    return RedirectResponse(api.url_path_for("api_v1_volume_pdf", kanton=kanton, volume=volume))


@html.get("/{kanton}/{volume}", name="document_list")
async def documents(
    kanton: str, volume: str, request: Request, lang: LangDependency, connection: DBDependency
):
    raise NotImplementedError


@html.get("/{kanton}/{volume}/{document}", name="document_view")
async def document(
    kanton: str,
    volume: str,
    document: str,
    request: Request,
    lang: LangDependency,
    connection: DBDependency,
):
    raise NotImplementedError


@html.get("/about/partners-and-funding", name="partners_and_funding")
async def partners_and_funding(request: Request, lang: LangDependency):
    raise NotImplementedError


@html.get("/about/tech", name="tech")
async def tech_docs(request: Request, lang: LangDependency):
    raise NotImplementedError


@html.get("/index/lemmata", name="lemmata")
async def list_lemmata(request: Request, lang: LangDependency):
    raise NotImplementedError


@html.get("/index/persons", name="persons")
async def list_persons(request: Request, lang: LangDependency):
    raise NotImplementedError


@html.get("/index/places", name="places")
async def list_places(request: Request, lang: LangDependency):
    raise NotImplementedError


@html.get("/index/terms", name="terms")
async def list_terms(request: Request, lang: LangDependency):
    raise NotImplementedError
