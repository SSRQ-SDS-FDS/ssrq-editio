from typing import AsyncGenerator

import pytest
from httpx import ASGITransport, AsyncClient

from ssrq_editio.entrypoints.app.main import app


@pytest.fixture(scope="module")
async def app_client() -> AsyncGenerator[AsyncClient, None]:
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        yield client
