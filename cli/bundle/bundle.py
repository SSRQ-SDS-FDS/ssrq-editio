from pathlib import Path

from glob import glob
from cli import config
from zipfile import ZipFile
from loguru import logger


def bundle_application(
    build_dir: Path, expath_file: Path, exist_app_dir_name: str, ignores: list[str]
):
    """Orchestrates the bundling of the application.

    Args:
        build_dir (Path): The target directory for the bundled application
        ignores (list[str]): A list of files and folders to ignore when bundling
    """
    check_and_clean_target_dir(build_dir)

    logger.info(f"Ignoring the following files and folders for bundling: {ignores}")
    files_to_bundle = find_files_to_bundle(config.PROJECT_ROOT, ignores)
    logger.info(f"Found {len(files_to_bundle)} files to bundle")

    package_name, package_version = get_infos_from_expath(expath_file)
    xar_name = f"{package_name}-{package_version}.xar"
    logger.info(f"Creating bundled application as {xar_name} in {build_dir}")
    create_xar(
        target_dir=build_dir,
        name=xar_name,
        root=config.PROJECT_ROOT,
        files=files_to_bundle,
        exist_app_dir_name=exist_app_dir_name,
    )


def check_and_clean_target_dir(target_dir: Path):
    """Helper function to create the target folder if it does not exist
    and clean it if it does.

    Args:
        target_dir (Path): The target folder
    """
    import shutil

    if target_dir.exists():
        shutil.rmtree(target_dir)
    target_dir.mkdir()


def find_files_to_bundle(source_dir: Path, ignores: list[str]):
    files = glob(str(source_dir.absolute()) + "/**", recursive=True)
    return [
        file
        for file in files
        if all(ignore_file_or_path not in file for ignore_file_or_path in ignores)
    ]


def get_infos_from_expath(expath: Path) -> tuple[str, str]:
    from xml.dom.minidom import parse as dom_parse

    package = dom_parse(str(expath)).getElementsByTagName("package")[0]
    package_name = package.getAttribute("abbrev")
    package_version = package.getAttribute("version")
    return package_name, package_version


def create_xar(target_dir: Path, name: str, root: Path, files: list[str], exist_app_dir_name: str):
    with ZipFile(target_dir / name, "w") as bundle:
        for file in files:
            if file.endswith(exist_app_dir_name):
                # Skip the exist app dir itself
                continue
            bundle.write(
                filename=file,
                arcname=file.replace(str(root) + "/", "").replace(
                    exist_app_dir_name + "/",
                    "",
                ),
            )
