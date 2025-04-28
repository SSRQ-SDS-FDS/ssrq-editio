from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse, RedirectResponse

from ssrq_editio.entrypoints.app.routers.api import api
from ssrq_editio.entrypoints.app.shared.dependencies import DBDependency, LangDependency
from ssrq_editio.entrypoints.app.views.models.document import DocumentViewModel
from ssrq_editio.entrypoints.app.views.models.entity import EntityViewModel
from ssrq_editio.entrypoints.app.views.models.index import IndexViewModel
from ssrq_editio.entrypoints.app.views.models.kanton import KantonViewModel
from ssrq_editio.entrypoints.app.views.models.volume import VolumeViewModel
from ssrq_editio.models.documents import DocumentType
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
    occurrence: str | None = None,
    page: int = 1,
    per_page: int = 25,
):
    return await EntityViewModel(
        request, lang, connection, entity_type, query, occurrence, page, per_page
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
    request: Request,
    lang: LangDependency,
    connection: DBDependency,
    kanton: KantonName,
    volume: str,
    query: str | None = None,
    facs: bool = False,
    doc_type: None | DocumentType = None,
    page: int = 1,
    per_page: int = 25,
    range_start: int | None = None,
    range_end: int | None = None,
) -> HTMLResponse:
    return await VolumeViewModel(
        request,
        lang,
        connection,
        kanton,
        volume,
        query,
        facs,
        doc_type,
        page,
        per_page,
        range_start,
        range_end,
    ).to_html()


@html.get("/{kanton}/{volume}/{document}.html", name="document_view_with_html_extension")
async def deprecated_document_html_view(
    kanton: KantonName,
    volume: str,
    document: str,
):
    return RedirectResponse(
        html.url_path_for("document_view", kanton=kanton, volume=volume, document=document)
    )


@html.get("/{kanton}/{volume}/{document}.xml", name="document_view_with_xml_extension")
async def deprecated_document_xml_view(
    kanton: KantonName,
    volume: str,
    document: str,
):
    return RedirectResponse(
        api.url_path_for("api_v1_document_xml", id=f"{kanton.value}-{volume}-{document}")
    )


@html.get("/{kanton}/{volume}/{document}", name="document_view")
async def document(
    kanton: KantonName,
    volume: str,
    document: str,
    request: Request,
    lang: LangDependency,
    connection: DBDependency,
):
    # return f"Page view for {kanton} {volume} {document}"
    return await DocumentViewModel(request, lang, connection, kanton, volume, document).to_html()


"""
    return await EntityViewModel(
        request, lang, connection, entity_type, query, occurrence, page, per_page
    ).to_html()

"""
