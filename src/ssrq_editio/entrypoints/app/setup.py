from pathlib import Path
from fastapi import APIRouter, FastAPI
from ssrq_editio.entrypoints.app.config import ASSET_DIR, TEMPLATE_DIR
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates


def app_factory(
    template_dir: Path,
    asset_dir: Path,
) -> tuple[FastAPI, Jinja2Templates]:
    app = FastAPI(docs_url="/api", redoc_url=None)
    app.mount("/static", StaticFiles(directory=asset_dir), name="static")
    templates = Jinja2Templates(directory=template_dir)

    return app, templates


def setup_routers(app: FastAPI, routers: tuple[APIRouter, ...]) -> None:
    for router in routers:
        app.include_router(router)


app, templates = app_factory(TEMPLATE_DIR, ASSET_DIR)
