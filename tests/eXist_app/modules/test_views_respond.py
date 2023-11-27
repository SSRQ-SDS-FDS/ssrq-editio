from collections.abc import Callable
from typing import Awaitable

import httpx
import pytest
from cli.config import DOCKER_DEV_SETTINGS

route_tester = Callable[[str], Awaitable[httpx.Response]]


@pytest.fixture
def request_route(async_http_client: httpx.AsyncClient) -> route_tester:
    async def _request_route(route: str) -> httpx.Response:
        return await async_http_client.get(
            f"http://localhost:{DOCKER_DEV_SETTINGS.dev.port}/exist/apps/ssrq{route}",
            headers={"Accept": "text/html"},
            follow_redirects=False,
            timeout=httpx.Timeout(5, connect=5),
        )

    return _request_route


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "route, code",
    [
        ("/", 200),
        ("/about/api", 200),
        ("/about/partners", 200),
        ("/about/api.json", 200),
        ("/about/foo", 404),
        ("/SG", 301),
    ],
)
async def test_routes(request_route: route_tester, route: str, code: int):
    """Test if a request to route, returns the expected status-code."""
    response = await request_route(route)
    assert response.status_code == code
