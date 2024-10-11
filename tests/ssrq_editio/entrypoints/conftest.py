from typing import AsyncGenerator
import pytest
from ssrq_editio.entrypoints.app.main import app
from httpx import ASGITransport, AsyncClient


@pytest.fixture(scope="module")
async def app_client() -> AsyncGenerator[AsyncClient, None]:
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        yield client
