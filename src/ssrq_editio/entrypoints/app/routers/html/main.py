from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse

from ssrq_editio.entrypoints.app.shared.dependencies import LangDependency
from ssrq_editio.entrypoints.app.views.models.index import IndexViewModel

html = APIRouter(default_response_class=HTMLResponse, include_in_schema=False)


@html.get("/")
async def index(request: Request, lang: LangDependency):
    return await IndexViewModel(request, lang).to_html()
