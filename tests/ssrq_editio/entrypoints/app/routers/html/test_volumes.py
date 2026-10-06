import pytest
from httpx import AsyncClient
from httpx._status_codes import codes
from parsel import Selector

from ssrq_editio.adapters.db.volumes import initialize_volume_with_editors
from ssrq_editio.models.volumes import Volume, VolumeType


@pytest.mark.anyio
async def test_volume_page_lists_test_volumes(app_client: AsyncClient):
    response = await app_client.get("/SG")
    assert response.status_code == codes.OK
    doc = Selector(text=response.text)
    cards = doc.css(".volume").getall()
    assert len(cards) == 1
    assert doc.css(".collaborateurs").get() is None


@pytest.mark.anyio
async def test_register_volume_card_links_to_pdf_without_article_list(
    app_client: AsyncClient, app_db_setup
):
    volume = Volume(
        key="ZG_1_3",
        sort_key=2,
        volume_type=VolumeType.REGISTER,
        kanton="ZG",
        name="1/3",
        prefix="SSRQ",
        title="Sachregister und Glossar",
        pdf="book/ZG_1.3.pdf",
        literature=None,
        project_page="/digital/retro/",
        editors=["Peter Stotz"],
    )
    await initialize_volume_with_editors(app_db_setup, volume)

    response = await app_client.get("/ZG")

    assert response.status_code == codes.OK
    doc = Selector(text=response.text)
    assert doc.css('.volume a[href*="/ZG/1_3?"]').get() is None
    pdf_link = doc.css('.volume a[href*="/ZG/1_3.pdf"]::attr(href)').get()
    assert pdf_link is not None
    assert "lang=de" in pdf_link
    assert "Sachregister und Glossar" in doc.css(".volume-title::text").get()

    response = await app_client.get("/ZG/1_3", follow_redirects=False)
    assert response.status_code == codes.TEMPORARY_REDIRECT
    assert response.headers["location"].endswith("/ZG/1_3.pdf")


@pytest.mark.anyio
@pytest.mark.parametrize(
    "lang, phrase",
    [
        ("de", "unter Mitarbeit von"),
        ("fr", "avec la collaboration de"),
        ("en", "with contributions from"),
        ("it", "con la collaborazione di"),
    ],
)
async def test_volume_card_shows_collaborateurs(app_client, app_db_setup, lang, phrase):
    volume = Volume(
        key="ZH_collaboration",
        sort_key=1,
        kanton="ZH",
        name="Collaboration",
        prefix="SSRQ",
        title="Bandtitel",
        pdf=None,
        literature=None,
        project_page=None,
        editors=["Eva Editor"],
        collaborateurs=["Zoe Mitarbeit", "Anna Mitarbeit"],
    )
    # The router fixtures share a database across tests.
    await app_db_setup.execute("DELETE FROM collaborateurs WHERE volume_id = ?", (volume.key,))
    await app_db_setup.execute("DELETE FROM editors WHERE volume_id = ?", (volume.key,))
    await app_db_setup.execute("DELETE FROM volumes WHERE id = ?", (volume.key,))
    await initialize_volume_with_editors(app_db_setup, volume)

    response = await app_client.get(f"/ZH?lang={lang}")

    assert response.status_code == codes.OK
    doc = Selector(text=response.text)
    line = doc.css(".volume .collaborateurs")
    assert " ".join(line.xpath("string(.)").get().split()) == (
        f"{phrase} Anna Mitarbeit, Zoe Mitarbeit"
    )
    assert "Eva Editor" in line.xpath("preceding-sibling::p[1]").get()
