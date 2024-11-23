import asyncio
import inspect

import typer

import ssrq_editio.entrypoints.cli.config as config  # type: ignore
from ssrq_editio.entrypoints.app.config import DB_NAME
from ssrq_editio.entrypoints.cli.handlers.db import setup
from ssrq_editio.services.logger import SSRQ_LOGGER

app = typer.Typer()


@app.command("prepare-db")
def prepare_db(
    clean: bool = typer.Option(False, help="Clean / remove the DB if it exists."),
    db: str = typer.Argument(DB_NAME, help="The name of the database."),
):
    """Prepare and popluate the database."""
    asyncio.run(setup(db, clean))


@app.command("show-config")
def show_config():
    """Show configuration variables used by the CLI."""
    for name, value in inspect.getmembers(config):
        if name.isupper():
            SSRQ_LOGGER.info(f"{name}: {value}")


if __name__ == "__main__":
    app()
