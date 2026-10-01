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
