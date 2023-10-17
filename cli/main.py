from typing import Literal, Optional
import typer

from cli import config
from cli.volumes import config_reader as vol_config
from cli.volumes import handle as vol_handle
from cli.misc_data import handle as misc_handle
from cli.sass import handle as sass_handle
from cli.bundle import settings as bundle_settings
from loguru import logger
import subprocess

app = typer.Typer(name="editio")


@app.command(
    "build",
    help="""Builds the editio eXist-DB application and stores the output
             as .xar in `build`.""",
)
def build(
    enable_upload: bool = typer.Option(
        False,
        "--enable-upload",
        help="Enable upload functionality inside the application.",
    ),
    use_cache: bool = typer.Option(
        True, "--use-cache", "-c", help="Control if the application uses the cache."
    ),
    update_data: bool = typer.Option(
        False,
        "--update-data",
        "-u",
        help="Update the data submodule before building the application.",
    ),
    env: Optional[str] = typer.Argument(
        None,
        help="The environment to build the application for – must be ['dev', 'prod'].",
    ),
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

    logger.info(
        f"Reading settings from {config.EDITIO_CONFIG} and merge them with CLI options"
    )
    settings = bundle_settings.merge_settings(
        settings=bundle_settings.read_settings(),
        cache=use_cache,
        upload=enable_upload,
        env=env,
    )
    logger.info(f"Using the following settings: {settings}")

    bundle_settings.write_settings_to_env_xml(settings, config.PROJECT_ROOT)
    vol_handle.handle_volumes(vol_config.read_config(), config.VOLUMES_TARGET)
    misc_handle.copy_misc_data(config.MISC_DATA_SOURCE, config.MISC_DATA_TARGET)
    sass_handle.compile_sass_to_css(config.SASS_SOURCE, config.CSS_TARGET)


if __name__ == "__main__":
    app()
