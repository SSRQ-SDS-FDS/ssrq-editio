from pathlib import Path
from fastapi import FastAPI
from ssrq_editio.entrypoints.app.config import ASSET_DIR, TEMPLATE_DIR
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates


def app_factory(template_dir: Path, asset_dir: Path) -> tuple[FastAPI, Jinja2Templates]:
    app = FastAPI()
    app.mount("/static", StaticFiles(directory=asset_dir), name="static")
    templates = Jinja2Templates(directory=template_dir)
    return app, templates


app, templates = app_factory(TEMPLATE_DIR, ASSET_DIR)
