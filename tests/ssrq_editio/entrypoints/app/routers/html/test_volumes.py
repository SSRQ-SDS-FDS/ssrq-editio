import pytest
from httpx import AsyncClient
from httpx._status_codes import codes
from parsel import Selector


@pytest.mark.anyio
async def test_volume_page_lists_test_volumes(app_client: AsyncClient):
    response = await app_client.get("/SG")
    assert response.status_code == codes.OK
    doc = Selector(text=response.text)
    cards = doc.css(".volume").getall()
    assert len(cards) == 1
