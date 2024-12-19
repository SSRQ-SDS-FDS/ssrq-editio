import importlib.metadata
from pathlib import Path

import jinjax
from fastapi import APIRouter, FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from jinja2_fragments.fastapi import Jinja2Blocks
from markdown import markdown  # type: ignore
from ssrq_utils.i18n.text import normalize_punctuation_marks

from ssrq_editio.entrypoints.app.config import ASSET_DIR, COMPONENT_DIR, TEMPLATE_DIR


def app_factory(
    template_dir: Path,
    component_dir: Path,
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
        version=importlib.metadata.version("ssrq_editio"),
        summary="API of the digital scholarly edition published by the Law Sources Foundation of the Swiss Lawyers Society",
        title="SSRQ · SDS · FDS / Editio API",
    )
    app.mount("/static", StaticFiles(directory=asset_dir), name="static")
    templates = Jinja2Blocks(directory=template_dir)

    # Set filters and globals for Jinja2
    templates.env.globals.update(norm_punct=normalize_punctuation_marks)
    templates.env.filters.update(markdown=markdown)

    # Add JinjaX extension, which allows us to us Component-based templates
    templates.env.add_extension(jinjax.JinjaX)
    catalog = jinjax.Catalog(jinja_env=templates.env)
    catalog.add_folder(component_dir)

    return app, templates


def setup_routers(app: FastAPI, routers: tuple[APIRouter, ...]) -> None:
    for router in routers:
        app.include_router(router)


app, templates = app_factory(TEMPLATE_DIR, COMPONENT_DIR, ASSET_DIR)
