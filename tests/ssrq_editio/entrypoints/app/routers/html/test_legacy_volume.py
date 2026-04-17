import pytest
from httpx import AsyncClient
from httpx._status_codes import codes


async def _set_volume_links(
    app_db_setup,
    volume_id: str,
    literature: str | None,
    pdf: str | None,
):
    await app_db_setup.execute(
        "UPDATE volumes SET literature = ?, pdf = ? WHERE id = ?",
        (literature, pdf, volume_id),
    )
    await app_db_setup.commit()


@pytest.mark.anyio
@pytest.mark.parametrize("suffix", ["-lit", "-lit.html"])
async def test_deprecated_lit_redirects_to_literature_when_available(
    app_client: AsyncClient, app_db_setup, suffix: str
):
    literature = "https://www.zotero.org/groups/5048222/ssrq/collections/JKFJK5W5"
    await _set_volume_links(app_db_setup, "SG_III_4", literature=literature, pdf="TeX/foo.pdf")

    response = await app_client.get(f"/SG/III_4{suffix}", follow_redirects=False)

    assert response.status_code == codes.TEMPORARY_REDIRECT
    assert response.headers["location"] == literature


@pytest.mark.anyio
@pytest.mark.parametrize("suffix", ["-lit", "-lit.html"])
async def test_deprecated_lit_redirects_to_pdf_when_literature_missing(
    app_client: AsyncClient, app_db_setup, suffix: str
):
    await _set_volume_links(app_db_setup, "SG_III_4", literature=None, pdf="TeX/foo.pdf")

    response = await app_client.get(f"/SG/III_4{suffix}", follow_redirects=False, params={"lang": "de"})

    assert response.status_code == codes.TEMPORARY_REDIRECT
    assert response.headers["location"] == "http://test/SG/III_4.pdf?lang=de"


@pytest.mark.anyio
@pytest.mark.parametrize("suffix", ["-lit", "-lit.html"])
async def test_deprecated_lit_returns_404_when_no_target_exists(
    app_client: AsyncClient, app_db_setup, suffix: str
):
    await _set_volume_links(app_db_setup, "SG_III_4", literature=None, pdf=None)

    response = await app_client.get(f"/SG/III_4{suffix}", follow_redirects=False)

    assert response.status_code == codes.NOT_FOUND


@pytest.mark.anyio
@pytest.mark.parametrize("suffix", ["-intro", "-intro.html"])
async def test_deprecated_intro_redirects_to_pdf_when_available(
    app_client: AsyncClient, app_db_setup, suffix: str
):
    await _set_volume_links(
        app_db_setup,
        "SG_III_4",
        literature="https://www.zotero.org/groups/5048222/ssrq/collections/JKFJK5W5",
        pdf="TeX/foo.pdf",
    )

    response = await app_client.get(f"/SG/III_4{suffix}", follow_redirects=False, params={"lang": "fr"})

    assert response.status_code == codes.TEMPORARY_REDIRECT
    assert response.headers["location"] == "http://test/SG/III_4.pdf?lang=fr"


@pytest.mark.anyio
@pytest.mark.parametrize("suffix", ["-intro", "-intro.html"])
async def test_deprecated_intro_returns_404_when_pdf_missing(
    app_client: AsyncClient, app_db_setup, suffix: str
):
    await _set_volume_links(
        app_db_setup,
        "SG_III_4",
        literature="https://www.zotero.org/groups/5048222/ssrq/collections/JKFJK5W5",
        pdf=None,
    )

    response = await app_client.get(f"/SG/III_4{suffix}", follow_redirects=False)

    assert response.status_code == codes.NOT_FOUND
