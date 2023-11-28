import re
import shutil
from pathlib import Path

from loguru import logger

from cli import config
from cli.volumes import config_reader

CSS_STYLESHEET_REGEX = re.compile(
    r'<\?xml-stylesheet type="text/css" href="https://www.ssrq-sds-fds.ch/tei/.*\.css"\?>'
)


def handle_volumes(
    vol_config: config_reader.VolumesConfig, target_dir: Path = config.BUILD_CONFIG.volumes.target
):
    check_target_folder(target_dir)
    create_canton_folders(vol_config, target_dir)
    for volume in vol_config.volumes:
        handle_volume(volume, target_dir / volume.canton)


def check_target_folder(target_dir: Path) -> None:
    """Helper function to check the target folder.

    If it exists, it is deleted and recreated.

    Args:
        target_dir (Path): The target folder

    Returns:
        None: Nothing"""
    if target_dir.exists():
        shutil.rmtree(target_dir)
    target_dir.mkdir()


def create_canton_folders(vol_config: config_reader.VolumesConfig, target_dir: Path) -> None:
    for canton in {volume.canton for volume in vol_config.volumes}:
        check_target_folder(target_dir / canton)


def handle_volume(volume: config_reader.Volume, target_dir: Path) -> None:
    logger.info(f"Handling files for volume {volume.name}")

    check_target_folder(target_dir / volume.name)

    volume_xml_source = volume.folder / "online"
    volume_target_dir = target_dir / volume.name

    if volume.include == "all":
        logger.info(f"Copying all xml files for volume {volume.name}")
        copy_data_files(volume_xml_source, volume_target_dir, "*.xml")
    else:
        logger.info(f"Copying only source files for volume {volume.name}")
        copy_data_files(volume_xml_source, volume_target_dir, "*[1-9].xml")

    postprocess_xml_files(list(volume_target_dir.glob("*.xml")))

    pdf_source = get_source_pdf_path(volume_source=volume.folder)
    logger.info(f"Copying pdf files for volume {volume.name}; using {pdf_source} as source")
    copy_pdf_files(pdf_source, volume_target_dir)


def copy_data_files(volume_source: Path, volume_target: Path, glob_pattern: str) -> None:
    for file in (volume_source).glob(glob_pattern):
        shutil.copy(file, volume_target)

    if (volume_source / "assets").exists():
        shutil.copytree(volume_source / "assets", volume_target / "assets")


def postprocess_xml_files(files: list[Path]) -> None:
    import fileinput

    with fileinput.input(files=files, inplace=True, mode="r") as file:
        for line in file:
            if len((new_line := CSS_STYLESHEET_REGEX.sub("", line)).strip()) > 0:
                print(new_line, end="")


def get_source_pdf_path(volume_source: Path) -> Path:
    tex_source = volume_source / "TEI2LaTeX"
    if (tex_source / "Cases").exists():
        return tex_source / "Cases"
    return tex_source


def copy_pdf_files(volume_source: Path, volume_target: Path) -> None:
    check_target_folder(volume_target / "pdf")

    for file in volume_source.glob("*.pdf"):
        shutil.copy(file, volume_target / "pdf")
