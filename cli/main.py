import typer

from cli import config
from cli.volumes import config_reader as vol_config
from cli.volumes import handle as vol_handle
from cli.misc_data import handle as misc_handle
from cli.sass import handle as sass_handle
from loguru import logger
import subprocess

app = typer.Typer(name="editio")


@app.command(
    "build",
    help="""Builds the editio eXist-DB application and stores the output
             as .xar in `build`.""",
)
def build(
    update_data: bool = typer.Option(
        False,
        "--update-data",
        "-u",
        help="Update the data submodule before building the application.",
    )
):
    logger.info("Starting build process")

    if update_data or config.VOLUMES_SOURCE.exists() is False:
        logger.info("Updating / fetching tei-volumes submodule - this may take a while")
        subprocess.run(
            [
                "git",
                "-C",
                config.PROJECT_ROOT,
                "submodule",
                "update",
                "--init",
                "--recursive",
            ],
            capture_output=True,
            check=True,
        )
        logger.info("Data submodule is up to date")

    vol_handle.handle_volumes(vol_config.read_config(), config.VOLUMES_TARGET)
    misc_handle.copy_misc_data(config.MISC_DATA_SOURCE, config.MISC_DATA_TARGET)
    sass_handle.compile_sass_to_css(config.SASS_SOURCE, config.CSS_TARGET)


if __name__ == "__main__":
    app()
