from http import HTTPStatus
from pathlib import Path

import httpx
import pytest

from ssrq_editio.adapters.entities import get_places
from ssrq_editio.models.entities import Places

my_test_client = httpx.Client(
    transport=httpx.MockTransport(
        lambda request: httpx.Response(HTTPStatus.NOT_FOUND, content="Not Found")
    )
)


@pytest.fixture()
def httpx_client(example_path: Path):
    def mock_response(request: httpx.Request):
        file_name = Path(request.url.path).name
        file_path = example_path / file_name
        if file_path.exists():
            content = file_path.read_text()
            return httpx.Response(HTTPStatus.OK, content=content)
        else:
            return httpx.Response(HTTPStatus.NOT_FOUND)

    return httpx.AsyncClient(transport=httpx.MockTransport(mock_response))


@pytest.mark.asyncio_cooperative
async def test_get_places(httpx_client: httpx.AsyncClient):
    result = await get_places(httpx_client, "http://testserver/places.xml")
    assert result is not None
    assert isinstance(result, Places)
    assert any(place.de_name is not None for place in result.entities)
