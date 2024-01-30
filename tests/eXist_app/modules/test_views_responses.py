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
            timeout=httpx.Timeout(15),
        )

    return _request_route


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "route, code",
    [
        ("/SG", 301),
        ("/SG/III_4/", 200),
        ("/SG/III_4/intro.html", 200),
        ("/SG/III_4/intro.xml", 301),
    ],
)
@pytest.mark.depends_on_data
async def test_views_with_data_dependency(request_route: route_tester, route: str, code: int):
    """Test if a request to route, returns the expected status-code."""
    response = await request_route(route)
    assert response.status_code == code


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "route, code",
    [
        ("/", 200),
        ("/about", 301),
        ("/about/partners-and-funding", 200),
        ("/about/foo", 404),
    ],
)
async def test_views_without_data_dependency(request_route: route_tester, route: str, code: int):
    """Test if a request to route, returns the expected status-code."""
    response = await request_route(route)
    assert response.status_code == code


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "route, code",
    [
        ("/about/api", 200),
        ("/about/api.json", 200),
    ],
)
async def test_api_routes_controlled_by_views_router(
    request_route: route_tester, route: str, code: int
):
    """Test if a request to route, returns the expected status-code."""
    response = await request_route(route)
    assert response.status_code == code
