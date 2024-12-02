import pytest
from httpx import AsyncClient
from httpx._status_codes import codes
from parsel import Selector
from ssrq_utils.lang.display import Lang


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    ("method", "expected_status_code"),
    [
        ("get", codes.OK),
        ("post", codes.METHOD_NOT_ALLOWED),
        ("put", codes.METHOD_NOT_ALLOWED),
        ("delete", codes.METHOD_NOT_ALLOWED),
        ("patch", codes.METHOD_NOT_ALLOWED),
    ],
)
async def test_index_request_methods(
    app_client: AsyncClient, method: str, expected_status_code: codes
):
    response = await getattr(app_client, method)("/")
    assert response.status_code == expected_status_code


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    ("lang"),
    [
        ("de"),
        ("en"),
        ("fr"),
    ],
)
async def test_index_html_has_lang(app_client: AsyncClient, lang: str):
    response = await app_client.get("/", params={"lang": lang})
    assert response.status_code == codes.OK
    assert f'lang="{lang}"' in response.text
    # also check, if X-Lang has precedence over lang query parameter
    response = await app_client.get("/", headers={"X-Lang": lang}, params={"lang": "it"})
    assert response.status_code == codes.OK
    assert f'lang="{lang}"' in response.text


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    ("lang"),
    [
        ("de"),
        ("en"),
        ("fr"),
    ],
)
async def test_index_html_has_i18n_title_and_description(
    app_client: AsyncClient, lang: str, translator
):
    response = await app_client.get("/", params={"lang": lang})
    assert response.status_code == codes.OK
    doc = Selector(text=response.text)
    html_title = doc.css("title::text").get()
    assert html_title is not None
    assert html_title == translator.translate(Lang.from_string(lang), "short_title")
    description = doc.css('meta[name="description"]::attr(content)').get()
    assert description is not None
    assert description == translator.translate(Lang.from_string(lang), "title")


@pytest.mark.asyncio_cooperative
async def test_index_html_has_kanton_cards(app_client: AsyncClient):
    response = await app_client.get("/")
    assert response.status_code == codes.OK
    doc = Selector(text=response.text)
    cards = doc.css(".kanton-card").getall()
    assert len(cards) == 23  # one card for every kanton
