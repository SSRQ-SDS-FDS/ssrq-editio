import pytest
from httpx import AsyncClient
from httpx._status_codes import codes


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
