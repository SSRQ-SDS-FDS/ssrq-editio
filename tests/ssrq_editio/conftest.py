from http import HTTPStatus
from pathlib import Path

import httpx
import pytest
from ssrq_utils.i18n.translator import Translator

from ssrq_editio.adapters.entities import get_keywords, get_lemmata, get_persons, get_places
from ssrq_editio.entrypoints.app.config import TRANSLATION_SOURCE

my_test_client = httpx.Client(
    transport=httpx.MockTransport(
        lambda request: httpx.Response(HTTPStatus.NOT_FOUND, content="Not Found")
    )
)


@pytest.fixture(scope="session")
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


@pytest.fixture(scope="session")
def example_path():
    return Path(__file__).parent / "examples"


@pytest.fixture(scope="session")
def translator():
    return Translator(TRANSLATION_SOURCE)


@pytest.fixture(scope="session")
def anyio_backend():
    return "asyncio"


@pytest.fixture(scope="session")
async def entities(httpx_client: httpx.AsyncClient):
    places = await get_places(httpx_client, "http://testserver/places.xml")
    keywords = await get_keywords(httpx_client, "http://testserver/keywords.xml")
    lemmata = await get_lemmata(httpx_client, "http://testserver/lemmata.xml")
    persons = await get_persons(httpx_client, "http://testserver/persons.xml")
    return (
        places,
        keywords,
        lemmata,
        persons,
    )
