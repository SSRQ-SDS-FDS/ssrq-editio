import re

import pytest
from httpx import AsyncClient
from ssrq_utils.lang.display import Lang
from starlette.requests import Request

from ssrq_editio.adapters.db.documents import get_documents_by_ft
from ssrq_editio.entrypoints.app.views.models.search import SearchViewModel
from ssrq_editio.models.documents import Document, DocumentFulltextResult


@pytest.mark.anyio
async def test_search_filter_options_reflect_url(app_client: AsyncClient):
    response = await app_client.get("/search", params={"area": "title"})

    assert response.status_code == 200
    options = re.findall(r'<input type="checkbox" name="area"[^>]*>', response.text)
    assert len(options) == 4
    assert 'value="title"' in options[0] and "checked" in options[0]
    assert all("checked" not in option for option in options[1:])


@pytest.mark.anyio
async def test_search_view_model_returns_complete_documents(app_db_setup):
    request = Request({"type": "http", "headers": [], "query_string": b""})
    view = SearchViewModel(request, Lang.DE, app_db_setup, "foo", 1, 25)

    content = (await view.create_context())["data"]["content"]

    assert content["total"] == 1
    result, places = content["results"][0]
    assert isinstance(result, DocumentFulltextResult)
    assert result.de_title == "foo"
    assert "<mark>foo</mark>" in result.ft_match
    assert result.ft_score > 0
    assert places


@pytest.mark.anyio
async def test_search_page_renders_fulltext_result(app_client: AsyncClient):
    response = await app_client.get("/search", params={"fts": "foo"})

    assert response.status_code == 200
    assert "SSRQ SG III/4 1/1" in response.text
    assert "<mark>foo</mark>" in response.text
    assert "Texttreffer" not in response.text
    assert "Score:" in response.text
    assert 'class="document-info"' in response.text
    assert 'href="http://test/SG/III_4/1-1?lang=de"' in response.text
    assert 'download="d56f1ce8-cec9-49ed-b54b-09f397adc2d8.xml"' in response.text


@pytest.mark.anyio
async def test_search_page_renders_subdocument(app_client: AsyncClient, app_db_setup, monkeypatch):
    result = (await get_documents_by_ft(app_db_setup, search="foo"))[0]
    subdocument = result.model_copy(
        update={"idno": "SSRQ-SG-III_4-1.1-1", "is_main": False, "printed_idno": "Teil 1"}
    )

    async def find_subdocument(connection, query, areas):
        return [subdocument]

    monkeypatch.setattr(
        "ssrq_editio.entrypoints.app.views.models.search.find_documents", find_subdocument
    )
    response = await app_client.get("/search", params={"fts": "foo", "lang": "fr"})

    assert response.status_code == 200
    assert "Teil 1" in response.text
    assert "/SG/III_4/1.1-1?lang=fr" in response.text
    assert "<mark>foo</mark>" in response.text


@pytest.mark.anyio
async def test_search_page_omits_snippet_without_relevance_score(
    app_client: AsyncClient, app_db_setup, monkeypatch
):
    result = (await get_documents_by_ft(app_db_setup, search="foo"))[0]
    document = result.model_dump(exclude={"ft_score", "ft_match"})

    async def find_without_fulltext(connection, query, areas):
        return [Document(**document)]

    monkeypatch.setattr(
        "ssrq_editio.entrypoints.app.views.models.search.find_documents", find_without_fulltext
    )
    response = await app_client.get("/search", params={"fts": "foo", "lang": "it"})

    assert response.status_code == 200
    assert "SSRQ SG III/4 1/1" in response.text
    assert "Punteggio:" not in response.text


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("query", "areas", "expected"),
    [
        ("foo", ["text"], True),
        ("foo", ["title"], False),
        ("foo", ["title", "text"], True),
        ("foo bar", ["text"], True),
        ("foo foo", ["text"], True),
        ("fo*", ["text"], True),
    ],
)
async def test_search_filters_selected_areas(app_client: AsyncClient, query, areas, expected):
    params = [("fts", query), *(("area", area) for area in areas)]
    response = await app_client.get("/search", params=params)

    assert response.status_code == 200
    assert ("SSRQ SG III/4 1/1" in response.text) is expected
