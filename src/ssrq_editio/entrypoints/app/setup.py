from pathlib import Path

import jinjax
from fastapi import APIRouter, FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

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
    app = FastAPI(docs_url="/api", redoc_url=None)
    app.mount("/static", StaticFiles(directory=asset_dir), name="static")
    templates = Jinja2Templates(directory=template_dir)
    templates.env.add_extension(jinjax.JinjaX)
    catalog = jinjax.Catalog(jinja_env=templates.env)
    catalog.add_folder(component_dir)

    return app, templates


def setup_routers(app: FastAPI, routers: tuple[APIRouter, ...]) -> None:
    for router in routers:
        app.include_router(router)


app, templates = app_factory(TEMPLATE_DIR, COMPONENT_DIR, ASSET_DIR)
