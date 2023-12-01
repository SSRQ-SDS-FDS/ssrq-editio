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
            follow_redirects=False,
            timeout=httpx.Timeout(15),
        )

    return _request_route


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "route, code",
    [
        ("/api/v1/FR/I_2_8/2-1.pdf", 200),
        ("/api/v1/FR/I_2_8/2-1.xml", 200),  # fallback for SSRQ-FR-I_2_8-2.0-1
        ("/api/v1/FR/I_2_8/2.0-1.xml", 200),
    ],
)
async def test_api_routes(request_route: route_tester, route: str, code: int):
    """Test if a request to an endpoints, returns the expected status-code."""
    response = await request_route(route)
    assert response.status_code == code
