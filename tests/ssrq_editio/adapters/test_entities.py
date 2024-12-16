import httpx
import pytest

from ssrq_editio.adapters.entities import get_keywords, get_lemmata, get_places
from ssrq_editio.models.entities import Keywords, Lemmata, Places


@pytest.mark.asyncio_cooperative
async def test_get_places(httpx_client: httpx.AsyncClient):
    result = await get_places(httpx_client, "http://testserver/places.xml")
    assert result is not None
    assert isinstance(result, Places)
    assert any(place.de_name is not None for place in result.entities)


@pytest.mark.asyncio_cooperative
async def test_get_keywords(httpx_client: httpx.AsyncClient):
    result = await get_keywords(httpx_client, "http://testserver/keywords.xml")
    assert result is not None
    assert isinstance(result, Keywords)
    assert any(place.de_name is not None for place in result.entities)


@pytest.mark.asyncio_cooperative
async def test_get_lemmata(httpx_client: httpx.AsyncClient):
    result = await get_lemmata(httpx_client, "http://testserver/lemmata.xml")
    assert result is not None
    assert isinstance(result, Lemmata)
    assert any(place.de_name is not None for place in result.entities)
