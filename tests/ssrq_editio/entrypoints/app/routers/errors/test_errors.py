import pytest
from httpx import AsyncClient


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("url", "status_code"),
    [
        ("/search?fts=!test", 500),
        ("/a/b/c", 422),
        ("/api/v1/kantons/ZH/bla.pdf", 404),
    ],
)
async def test_status_code(app_client: AsyncClient, url: str, status_code: int):
    response = await app_client.get(url)
    assert response.status_code == status_code


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("url", "error_text"),
    [
        ("/search?fts=!test&lang=de", "Ups! Da ist wohl etwas schiefgelaufen."),
        ("/search?fts=!test&lang=en", "Oops! Something went wrong."),
        ("/search?fts=!test&lang=fr", "Oups ! Quelque chose s’est mal passé."),
        ("/search?fts=!test&lang=it", "Ops! Qualcosa è andato storto."),
        ("/a/b/c?lang=en", "Oops! Something went wrong."),
    ],
)
async def test_error_text(app_client: AsyncClient, url: str, error_text: str):
    response = await app_client.get(url)
    assert error_text in response.text
