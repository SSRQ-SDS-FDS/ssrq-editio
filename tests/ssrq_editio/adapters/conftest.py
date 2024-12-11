from http import HTTPStatus
from pathlib import Path

import httpx
import pytest

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
