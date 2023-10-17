from typing import Optional
import typer

from cli import config
from cli.volumes import config_reader as vol_config
from cli.volumes import handle as vol_handle
from cli.misc_data import handle as misc_handle
from cli.sass import handle as sass_handle
from cli.bundle import settings as bundle_settings
from cli.bundle.bundle import bundle_application
from loguru import logger
import subprocess
from os import environ

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
    bundle_application(
        config.PROJECT_ROOT / "build",
        config.COMMON_IGNORES if settings.env == "dev" else config.PROD_IGNORES,
    )


@app.command(
    help="""Show logs from the eXist-DB docker container.""",
)
def logs(
    mode: str = typer.Argument(
        "dev",
        help="The mode to run the application in – must be ['dev', 'prod'].",
    ),
):
    execute_docker_compose_command("logs", ["-f"], mode)


@app.command(
    help="""Run the app inside an eXist-DB docker container.""",
)
def run(
    clean: bool = typer.Option(
        True,
        "--clean",
        "-c",
        help="If true a fresh container will be created from scratch.",
    ),
    mode: str = typer.Argument(
        "dev",
        help="The mode to run the application in – must be ['dev', 'prod'].",
    ),
):
    check_build_dir()

    create_dev_setup(mode)

    docker_params = (
        ["--build", "--detach", "--remove-orphans", "--renew-anon-volumes"]
        if clean
        else ["--detach"]
    )

    execute_docker_compose_command("up", docker_params, mode)


@app.command(
    help="""Stop the eXist-DB docker container.""",
)
def stop(
    remove_volumes: bool = typer.Option(
        False,
        "--remove-volumes",
        "-r",
        help="If true the volumes will be removed as well.",
    ),
    mode: str = typer.Argument(
        "dev",
        help="The mode to run the application in – must be ['dev', 'prod'].",
    ),
):
    execute_docker_compose_command("down", ["-v"] if remove_volumes else [], mode)


def check_build_dir():
    if (build_dir := config.PROJECT_ROOT / "build").exists() is False:
        logger.error(
            f"Build directory {build_dir} does not exist – run 'editio build' first"
        )
        raise typer.Exit(1)


def create_dev_setup(mode: str):
    """Creates a dev-setup, if the mode is 'dev' and sets the necessary
    environment variables."""
    if mode != "dev":
        return
    set_sys_env_variable("EXIST_PASSWORD", config.DEV_DUMMY_PASSWORD)
    set_sys_env_variable("EDITIO_PORT", config.EDITIO_PORT)


def set_sys_env_variable(name: str, value: str):
    environ[name] = value


def execute_docker_compose_command(command: str, params: list[str], mode: str):
    match (mode):
        case "dev":
            logger.info(f"Executing command '{command}' in dev mode")
            subprocess.run(
                ["docker-compose", "-f", str(config.DEV_COMPOSE_FILE), command]
                + params,
                check=True,
            )
        case "prod":
            logger.warning("Not implemented yet")
            typer.Exit(0)
        case _:
            raise typer.BadParameter("Mode must be either 'dev' or 'prod'")


if __name__ == "__main__":
    app()
