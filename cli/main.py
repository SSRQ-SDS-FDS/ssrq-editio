import typer

from cli import config
from cli.volumes import config_reader as vol_config
from cli.volumes import handle as vol_handle
from cli.misc_data import handle as misc_handle
from loguru import logger

app = typer.Typer(name="editio")


@app.command(
    "build",
    help="""Builds the editio eXist-DB application and stores the output
             as .xar in `build`.""",
)
def build():
    logger.info("Starting build process")
    vol_handle.handle_volumes(vol_config.read_config(), config.VOLUMES_TARGET)
    misc_handle.copy_misc_data(config.MISC_DATA_SOURCE, config.MISC_DATA_TARGET)


if __name__ == "__main__":
    app()
