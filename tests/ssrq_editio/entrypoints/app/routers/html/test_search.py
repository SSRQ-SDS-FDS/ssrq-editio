import pytest
from httpx import AsyncClient
from ssrq_utils.lang.display import Lang
from starlette.requests import Request

from ssrq_editio.entrypoints.app.views.models.search import SearchViewModel
from ssrq_editio.models.documents import DocumentFulltextResult


@pytest.mark.anyio
async def test_search_view_model_returns_complete_documents(app_db_setup):
    request = Request({"type": "http", "headers": [], "query_string": b""})
    view = SearchViewModel(request, Lang.DE, app_db_setup, "foo", 1, 25)

    content = (await view.create_context())["data"]["content"]

    assert content["total"] == 1
    result = content["results"][0]
    assert isinstance(result, DocumentFulltextResult)
    assert result.de_title == "foo"
    assert "<mark>foo</mark>" in result.ft_match


@pytest.mark.anyio
async def test_search_page_renders_fulltext_result(app_client: AsyncClient):
    response = await app_client.get("/search", params={"fts": "foo"})

    assert response.status_code == 200
    assert "SSRQ SG III/4 1/1" in response.text
    assert "<mark>foo</mark>" in response.text
