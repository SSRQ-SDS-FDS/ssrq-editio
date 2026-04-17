import pytest
from httpx import AsyncClient


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("url", "lang", "redirected_url"),
    [
        ("/about/editorial_principles", "de", "https://schema.ssrq-sds-fds.ch/latest/"),
        ("/about/editorial_principles", "en", "https://schema.ssrq-sds-fds.ch/latest/"),
        ("/about/editorial_principles", "fr", "https://schema.ssrq-sds-fds.ch/latest/fr/"),
        ("/about/editorial_principles", "it", "https://schema.ssrq-sds-fds.ch/latest/"),
        (
            "/about/digital-edition",
            "de",
            "https://ssrq-sds-fds.ch/blog/2026/02/27/startschuss-f%C3%BCr-neue-forschungsplattform/",
        ),
        (
            "/about/digital-edition",
            "en",
            "https://ssrq-sds-fds.ch/en/blog/2026/02/27/startschuss-f%C3%BCr-neue-forschungsplattform/",
        ),
        (
            "/about/digital-edition",
            "fr",
            "https://ssrq-sds-fds.ch/fr/blog/2026/02/27/startschuss-f%C3%BCr-neue-forschungsplattform/",
        ),
        (
            "/about/digital-edition",
            "it",
            "https://ssrq-sds-fds.ch/it/blog/2026/02/27/startschuss-f%C3%BCr-neue-forschungsplattform/",
        ),
        ("/about/partners-and-funding", "de", "https://ssrq-sds-fds.ch/projects/cooperations/"),
        ("/about/partners-and-funding", "en", "https://ssrq-sds-fds.ch/en/projects/cooperations/"),
        ("/about/partners-and-funding", "fr", "https://ssrq-sds-fds.ch/fr/projects/cooperations/"),
        ("/about/partners-and-funding", "it", "https://ssrq-sds-fds.ch/it/projects/cooperations/"),
    ],
)
async def test_redirect_on_about_pages(
    app_client: AsyncClient,
    url: str,
    lang: str,
    redirected_url: str,
):
    response = await app_client.get(url, params={"lang": lang})
    assert response.status_code == 302
    assert response.headers.get("Location") == redirected_url
