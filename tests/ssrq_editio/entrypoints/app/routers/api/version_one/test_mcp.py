import json
from typing import AsyncGenerator

import pytest
from httpx import ASGITransport, AsyncClient

from ssrq_editio.entrypoints.app.main import app


@pytest.fixture
async def mcp_client() -> AsyncGenerator[AsyncClient, None]:
    """Provide the shared async HTTP client with the MCP lifespan activated."""
    async with app.router.lifespan_context(app):
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            yield client


@pytest.mark.anyio
async def test_mcp_endpoint_supports_initialization_and_tool_discovery(
    mcp_client: AsyncClient,
):
    """The mounted MCP transport accepts the handshake and exposes the tool registry."""
    initialize_request = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2025-03-26",
            "capabilities": {},
            "clientInfo": {"name": "test-client", "version": "1.0"},
        },
    }
    headers = {
        "Accept": "application/json, text/event-stream",
        "Content-Type": "application/json",
    }

    response = await mcp_client.post(
        "/api/v1/mcp", json=initialize_request, headers=headers, follow_redirects=True
    )

    assert response.status_code == 200
    session_id = response.headers["mcp-session-id"]

    headers["Mcp-Session-Id"] = session_id
    await mcp_client.post(
        "/api/v1/mcp/",
        json={"jsonrpc": "2.0", "method": "notifications/initialized"},
        headers=headers,
    )
    response = await mcp_client.post(
        "/api/v1/mcp/",
        json={"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}},
        headers=headers,
    )

    assert response.status_code == 200
    message = json.loads(response.text.split("data: ", maxsplit=1)[1])
    assert message == {"jsonrpc": "2.0", "id": 2, "result": {"tools": []}}
