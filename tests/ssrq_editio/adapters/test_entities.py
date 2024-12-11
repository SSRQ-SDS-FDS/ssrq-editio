import httpx
import pytest

from ssrq_editio.adapters.entities import get_places
from ssrq_editio.models.entities import Places


@pytest.mark.asyncio_cooperative
async def test_get_places(httpx_client: httpx.AsyncClient):
    result = await get_places(httpx_client, "http://testserver/places.xml")
    assert result is not None
    assert isinstance(result, Places)
    assert any(place.de_name is not None for place in result.entities)
