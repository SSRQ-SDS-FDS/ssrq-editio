from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse

from ssrq_editio.entrypoints.app.shared.dependencies import DBDependency, LangDependency
from ssrq_editio.entrypoints.app.views.models.index import IndexViewModel

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
async def volumes(kanton: str, request: Request, lang: LangDependency, connection: DBDependency):
    raise NotImplementedError


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
