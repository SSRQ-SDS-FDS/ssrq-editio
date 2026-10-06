from fastapi import Request
from fastapi.responses import RedirectResponse

from ssrq_editio.entrypoints.app.routers import api, html, register_error_handlers
from ssrq_editio.entrypoints.app.routers.api.version_one import mcp_app
from ssrq_editio.entrypoints.app.setup import app, setup_routers


@app.api_route("/api/v1/mcp", methods=["GET", "POST", "DELETE"], include_in_schema=False)
async def mcp_endpoint_redirect(request: Request) -> RedirectResponse:
    """Redirect the slash-less MCP URL while preserving the request method."""
    return RedirectResponse(url=f"{request.url.path}/", status_code=307)


app.mount("/api/v1/mcp", mcp_app, name="mcp")

setup_routers(
    app,
    register_error_handlers,
    (
        api,
        html,
    ),
)
