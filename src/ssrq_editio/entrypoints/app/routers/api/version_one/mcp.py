"""MCP server configuration for the SSRQ/Editio application."""

from fastmcp import FastMCP

mcp: FastMCP = FastMCP(
    name="SSRQ · SDS · FDS / Editio",
    instructions=(
        "Use this server to explore the digital scholarly edition of the Swiss Law Sources."
    ),
)

# The ASGI application is created once and mounted into the existing FastAPI application.
# Its lifespan is passed to FastAPI so that FastMCP can initialize its HTTP session manager.
mcp_app = mcp.http_app(path="/", transport="streamable-http")
