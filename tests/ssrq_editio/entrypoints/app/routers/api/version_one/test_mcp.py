import json
from typing import AsyncGenerator

import pytest
from httpx import ASGITransport, AsyncClient

from ssrq_editio.entrypoints.app.main import app
from ssrq_editio.entrypoints.app.routers.api.version_one import mcp as mcp_server


@pytest.fixture
async def mcp_client() -> AsyncGenerator[AsyncClient, None]:
    """Provide the shared async HTTP client with the MCP lifespan activated."""
    async with app.router.lifespan_context(app):
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            yield client


@pytest.mark.anyio
async def test_mcp_endpoint_supports_initialization_and_tool_discovery(
    mcp_client: AsyncClient,
    app_db_setup,
    monkeypatch: pytest.MonkeyPatch,
):
    """The mounted MCP transport accepts the handshake and exposes the tool registry."""
    async def test_db_session():
        yield app_db_setup

    monkeypatch.setattr(mcp_server, "db_connection", test_db_session)

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
    assert [tool["name"] for tool in message["result"]["tools"]] == [
        "search_documents",
        "resolve_entity",
    ]

    response = await mcp_client.post(
        "/api/v1/mcp/",
        json={
            "jsonrpc": "2.0",
            "id": 3,
            "method": "tools/call",
            "params": {"name": "search_documents", "arguments": {"query": "foo"}},
        },
        headers=headers,
    )

    assert response.status_code == 200
    message = json.loads(response.text.split("data: ", maxsplit=1)[1])
    assert message["result"]["structuredContent"]["total"] == 1

    response = await mcp_client.post(
        "/api/v1/mcp/",
        json={
            "jsonrpc": "2.0",
            "id": 4,
            "method": "tools/call",
            "params": {
                "name": "resolve_entity",
                "arguments": {"entity_type": "keywords", "entity_id": "key000001"},
            },
        },
        headers=headers,
    )

    assert response.status_code == 200
    message = json.loads(response.text.split("data: ", maxsplit=1)[1])
    resolved_entity = message["result"]["structuredContent"]["result"]
    assert resolved_entity["id"] == "key000001"
    assert resolved_entity["de_name"] == "Abt"
    assert resolved_entity["de_definition"]


@pytest.mark.anyio
async def test_mcp_endpoint_is_documented_in_openapi(app_client: AsyncClient):
    """The mounted MCP transport is visible in the application's API documentation."""
    response = await app_client.get("/openapi.json")

    assert response.status_code == 200
    schema = response.json()
    assert "MCP" in [tag["name"] for tag in schema["tags"]]
    assert schema["paths"]["/api/v1/mcp/"]["post"]["tags"] == ["MCP"]
