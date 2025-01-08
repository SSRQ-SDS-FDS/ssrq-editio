import asyncio
import inspect
from pathlib import Path

import typer

import ssrq_editio.entrypoints.cli.config as config  # type: ignore
from ssrq_editio.adapters.db.connection import db_session
from ssrq_editio.entrypoints.app.config import DB_NAME
from ssrq_editio.entrypoints.cli.config import VOLUME_CONFIG
from ssrq_editio.entrypoints.cli.handlers.db import setup, setup_entities
from ssrq_editio.services.logger import SSRQ_LOGGER

app = typer.Typer()


@app.command("prepare-db")
def prepare_db(
    clean: bool = typer.Option(False, help="Clean / remove the DB if it exists."),
    db: str = typer.Argument(DB_NAME, help="The name of the database."),
    config: Path = typer.Argument(VOLUME_CONFIG, help="The path to the volume config."),
    data: Path = typer.Argument(config.VOLUME_SRC, help="The path to the volume data."),
):
    """Prepare and popluate the database."""
    asyncio.run(setup(db, clean, config, data))


@app.command("fetch-entities")
def fetch_entities(
    db: str = typer.Argument(DB_NAME, help="The name of the database."),
):
    """Fetches entities and inserts them into the DB. The tables get pruned before."""

    async def reinsert_entities():
        async for session in db_session(db):
            await setup_entities(connection=session, prune=True)

    asyncio.run(reinsert_entities())


@app.command("show-config")
def show_config():
    """Show configuration variables used by the CLI."""
    for name, value in inspect.getmembers(config):
        if name.isupper():
            SSRQ_LOGGER.info(f"{name}: {value}")


if __name__ == "__main__":
    app()
