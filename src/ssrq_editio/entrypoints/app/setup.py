import importlib.metadata
from pathlib import Path
from typing import Any, Callable, Sequence

import jinjax
from fastapi import APIRouter, FastAPI
from fastapi.openapi.utils import get_openapi
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from jinja2_fragments.fastapi import Jinja2Blocks
from markdown import markdown  # type: ignore
from ssrq_utils.i18n.text import normalize_punctuation_marks

from ssrq_editio.entrypoints.app.config import ASSET_DIR, COMPONENT_DIR, ICON_DIR, TEMPLATE_DIR
from ssrq_editio.entrypoints.app.routers.api.version_one import mcp_app
from ssrq_editio.entrypoints.app.settings import get_settings
from ssrq_editio.entrypoints.app.shared.version import get_display_version
from ssrq_editio.entrypoints.app.views.utils import (
    create_entity_preview_by_id,
    display_sub_document_info,
    render_template_string,
)
from ssrq_editio.services.documents import map_facs_to_iiif_urls
from ssrq_editio.services.monitoring import setup_error_monitoring
from ssrq_editio.services.occurrences import group_and_sort_idnos
from ssrq_editio.services.utils import create_permalink


def app_factory(
    template_dir: Path,
    component_dir: Sequence[Path],
    asset_dir: Path,
) -> tuple[FastAPI, Jinja2Templates]:
    """A factory function to create a FastAPI app and setup
    the Jinja2Templates instance for rendering templates.

    Args:
        template_dir (Path): The directory containing the templates.
        component_dir (Path): The directory containing the components.
        asset_dir (Path): The directory containing the static assets.

    Returns:
        tuple[FastAPI, Jinja2Templates]: The FastAPI app and Jinja2Templates instance.
    """
    app = FastAPI(
        docs_url="/api",
        redoc_url=None,
        openapi_tags=[
            {
                "name": "MCP",
                "description": "Model Context Protocol interface for exploring the edition – versioned in the same way as the main API.",
            },
            {
                "name": "v1",
                "description": "The first version of the public API.",
            },
        ],
        lifespan=mcp_app.lifespan,
        version=importlib.metadata.version("ssrq_editio"),
        summary="API of the digital scholarly edition published by the Law Sources Foundation of the Swiss Lawyers Society",
        title="SSRQ · SDS · FDS / Editio API",
    )

    def openapi_with_mcp() -> dict[str, Any]:
        """Add the mounted MCP transport to the OpenAPI documentation."""
        if app.openapi_schema:
            return app.openapi_schema

        openapi_schema = get_openapi(
            title=app.title,
            version=app.version,
            summary=app.summary,
            routes=app.routes,
            tags=app.openapi_tags,
        )
        openapi_schema["paths"]["/api/v1/mcp/"] = {
            "post": {
                "tags": ["MCP"],
                "summary": "MCP Streamable HTTP transport",
                "description": "MCP clients use this endpoint for JSON-RPC communication.",
                "operationId": "mcp_transport",
                "responses": {"200": {"description": "MCP JSON-RPC response."}},
            }
        }
        app.openapi_schema = openapi_schema
        return openapi_schema

    app.openapi = openapi_with_mcp  # type: ignore[method-assign]
    app.mount("/static", StaticFiles(directory=asset_dir), name="static")
    templates = Jinja2Blocks(directory=template_dir)

    # Set filters and globals for Jinja2
    templates.env.globals.update(norm_punct=normalize_punctuation_marks)
    templates.env.globals.update(group_and_sort_idnos=group_and_sort_idnos)
    templates.env.globals.update(create_entity_preview_by_id=create_entity_preview_by_id)
    templates.env.globals.update(display_sub_document_info=display_sub_document_info)
    templates.env.filters.update(markdown=markdown)
    templates.env.filters.update(permalink=create_permalink)
    templates.env.filters.update(render_template_string=render_template_string)
    templates.env.filters.update(map_facs_to_iiif_urls=map_facs_to_iiif_urls)
    templates.env.globals.update(project_version=get_display_version())

    # Add JinjaX extension, which allows us to us Component-based templates
    templates.env.add_extension(jinjax.JinjaX)
    catalog = jinjax.Catalog(jinja_env=templates.env)
    for directory in component_dir:
        catalog.add_folder(directory)

    return app, templates


def setup_routers(
    app: FastAPI, register_error_handlers: Callable[[FastAPI], None], routers: tuple[APIRouter, ...]
) -> None:
    setup_error_monitoring(get_settings())
    for router in routers:
        app.include_router(router)
    register_error_handlers(app)


app, templates = app_factory(TEMPLATE_DIR, (COMPONENT_DIR, ICON_DIR), ASSET_DIR)
