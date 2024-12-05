from pathlib import Path
from typing import AsyncGenerator

from aiosqlite import Connection
from pydantic_core import from_json

from ssrq_editio.adapters.db.volumes import list_volumes_with_editors
from ssrq_editio.adapters.file import stream
from ssrq_editio.models.kantons import KantonName
from ssrq_editio.models.volumes import Volume
from ssrq_editio.services.xslt.transformer import apply_xslt


def create_search_pattern(volume: Volume, content_folder: str = "online") -> str:
    """Create a glob-search-pattern for all documents of a volume.

    Uses the online-folder per default.

    Args:
        volume (Volume): Volume object.
        content_folder (str, optional): Folder to search in. Defaults to 'online'.
    """
    return f"{volume.key}/{content_folder}/*-1.xml"


async def fill_volume_info_from_xml(
    xml_src: Path, volume: Volume, xslt_script: str = "volume_info.xslt"
):
    """This function fills the volume object with dynamic
    information, which is extracted from a TEI-XML file.

    Args:
        xml_src (Path): Path to the TEI-XML file.
        volume (Volume): Volume object.
        xslt_script (str, optional): XSLT script to use. Defaults to "volume_info.xslt".

    Returns:
        Volume: Updated volume object

    Raises:
        ValueError: If XSLT transformation failed / returned None.
    """
    result = await apply_xslt((xml_src,), xslt_script)

    if result[0] is None:
        raise ValueError(f"Could not update volume info for {volume.key}, XSLT failed.")

    return volume.model_copy(update=from_json(result[0]))


async def stream_volume_pdf(
    kanton: KantonName, volume: str, connection: Connection, data_volume_src: Path
) -> AsyncGenerator[bytes, None]:
    """Stream the content of a volume PDF.

    Args:
        kanton (KantonName): KantonName enum object.
        volume (str): Volume key.
        connection (Connection): SQLite connection.

    Yields:
        AsyncGenerator[bytes, None]: Bytes of the file.

    Raises:
        ValueError: If volume or kanton is not found.
    """
    volumes = await list_volumes_with_editors(connection, kanton.value)

    if volumes is None:
        raise ValueError(f"Could not find any volumes for {kanton.value}")

    volume_info = next((v for v in volumes if v.machine_name == volume), None)

    if volume_info is None:
        raise ValueError(f"Could not find volume {volume} for {kanton.value}")

    volume_path = (
        data_volume_src
        / f"{kanton.value}_{volume_info.machine_name}"
        / "TeX"
        / f"{volume_info.prefix}-{volume_info.kanton}-{volume_info.machine_name}.pdf"
    )

    return stream(volume_path)
