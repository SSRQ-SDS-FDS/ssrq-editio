from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse, RedirectResponse

from ssrq_editio.entrypoints.app.routers.api import api
from ssrq_editio.entrypoints.app.shared.dependencies import (
    DBDependency,
    LangDependency,
    TransformerDependency,
)
from ssrq_editio.entrypoints.app.views.models.document import DocumentViewModel
from ssrq_editio.entrypoints.app.views.models.entity import EntityViewModel
from ssrq_editio.entrypoints.app.views.models.index import IndexViewModel
from ssrq_editio.entrypoints.app.views.models.kanton import KantonViewModel
from ssrq_editio.entrypoints.app.views.models.legacy_volume import (
    LegacyVolumeRedirectViewModel,
    LegacyVolumeTarget,
)
from ssrq_editio.entrypoints.app.views.models.search import SearchViewModel
from ssrq_editio.entrypoints.app.views.models.volume import VolumeViewModel
from ssrq_editio.models.documents import DocumentType
from ssrq_editio.models.entities import EntityTypes
from ssrq_editio.models.kantons import KantonName
from ssrq_editio.services.utils import build_project_url, build_schema_url

html = APIRouter(default_response_class=HTMLResponse, include_in_schema=False)


@html.get("/")
async def index(request: Request, lang: LangDependency, connection: DBDependency):
    return await IndexViewModel(request, lang, connection).to_html()


# Routes, which are direct child of the root must be placed before such routes,
# which use path parametzers
async def entities(request: Request):
    """Redirect all requests to the main index page, to
    the subpage, which lists all keywords."""
    return RedirectResponse(html.url_path_for("entity_view", entity_type="keywords"))


@html.get("/search", name="search")
async def search(
    request: Request,
    lang: LangDependency,
    connection: DBDependency,
    page: int = 1,
    per_page: int = 25,
    fts: str | None = None,
):
    return await SearchViewModel(
        request=request,
        lang=lang,
        connection=connection,
        query=fts,
        current_page=page,
        per_page=per_page,
    ).to_html()


@html.get(
    "/about/editorial_principles",
    name="editorial_principles",
    response_class=RedirectResponse,
    status_code=302,
)
async def editorial_principles(request: Request, lang: LangDependency):
    return build_schema_url("latest", lang, "")


@html.get(
    "/about/digital-edition", name="info_edition", response_class=RedirectResponse, status_code=302
)
async def scholarly_information(request: Request, lang: LangDependency):
    return build_project_url(lang, "blog/2026/02/27/startschuss-f%C3%BCr-neue-forschungsplattform/")


@html.get(
    "/about/partners-and-funding",
    name="partners_and_funding",
    response_class=RedirectResponse,
    status_code=302,
)
async def partners_and_funding(request: Request, lang: LangDependency):
    return build_project_url(lang, "projects/cooperations/")


@html.get("/index", name="entities")
@html.get("/index/{entity_type}", name="entity_view")
async def list_entities(
    request: Request,
    lang: LangDependency,
    connection: DBDependency,
    entity_type: EntityTypes = EntityTypes.LEMMATA,
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


@html.get("/{kanton}/{volume}-intro", name="deprecated_volume_intro")
@html.get("/{kanton}/{volume}-intro.html", name="deprecated_volume_intro_with_html_extension")
async def deprecated_volume_intro(
    request: Request,
    lang: LangDependency,
    connection: DBDependency,
    kanton: KantonName,
    volume: str,
):
    return await LegacyVolumeRedirectViewModel(
        request=request,
        lang=lang,
        connection=connection,
        kanton=kanton,
        volume=volume,
        target=LegacyVolumeTarget.INTRO,
    ).to_response()


@html.get("/{kanton}/{volume}-lit", name="deprecated_volume_lit")
@html.get("/{kanton}/{volume}-lit.html", name="deprecated_volume_lit_with_html_extension")
async def deprecated_volume_lit(
    request: Request,
    lang: LangDependency,
    connection: DBDependency,
    kanton: KantonName,
    volume: str,
):
    return await LegacyVolumeRedirectViewModel(
        request=request,
        lang=lang,
        connection=connection,
        kanton=kanton,
        volume=volume,
        target=LegacyVolumeTarget.LIT,
    ).to_response()


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


@html.get("/{kanton}/{volume}/{document}.pdf", name="document_view_with_pdf_extension")
async def deprecated_document_pdf_view(
    kanton: KantonName,
    volume: str,
    document: str,
):
    return RedirectResponse(html.url_path_for("kanton", kanton=kanton))


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
    transformer: TransformerDependency,
):
    return await DocumentViewModel(
        request, lang, connection, kanton, volume, document, transformer
    ).to_html()
