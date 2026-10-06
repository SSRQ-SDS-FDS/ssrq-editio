from pathlib import Path
from typing import AsyncGenerator

import cachebox
from aiosqlite import Connection
from pydantic_core import from_json

from ssrq_editio.adapters.db.kantons import list_kantons
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
    xml_src: Path | tuple[Path, ...], volume: Volume, xslt_script: str = "volume_info.xslt"
):
    """This function fills the volume object with dynamic
    information extracted from the main TEI-XML files of a volume.

    Args:
        xml_src: One TEI-XML file or all main files of the volume.
        volume (Volume): Volume object.
        xslt_script (str, optional): XSLT script to use. Defaults to "volume_info.xslt".

    Returns:
        Volume: Updated volume object

    Raises:
        ValueError: If XSLT transformation failed / returned None.
    """
    sources = (xml_src,) if isinstance(xml_src, Path) else xml_src
    if not sources:
        raise ValueError(f"Could not update volume info for {volume.key}, no XML files.")
    results = await apply_xslt(sources, xslt_script)
    if any(result.value is None for result in results):
        raise ValueError(f"Could not update volume info for {volume.key}, XSLT failed.")

    metadata = [from_json(result.value) for result in results if result.value is not None]
    editors = {name for item in metadata for name in item["editors"]}
    collaborateurs = {name for item in metadata for name in item["collaborateurs"]} - editors
    return volume.model_copy(
        update={**metadata[0], "collaborateurs": sorted(collaborateurs, key=str.casefold)}
    )


async def stream_volume_pdf(
    kanton: KantonName,
    volume: str,
    connection: Connection,
    data_volume_src: Path,
    suffix: str | None = None,
) -> AsyncGenerator[bytes, None]:
    """Stream the content of a volume PDF.

    Args:
        kanton (KantonName): KantonName enum object.
        volume (str): Volume key.
        connection (Connection): SQLite connection.
        data_volume_src (Path): The source of the current volume
        suffix (str | None): ``-translated`` selects the configured translated PDF.
            Omit it to select the configured original PDF.

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

    # Assign PDF name based on suffix parameter.
    match volume_info.pdf, suffix, volume_info.translated_pdf:
        case str() as pdf_name, None, _:
            pass
        case _, "-translated", str() as pdf_name:
            pass
        case _:
            raise ValueError(f"Unknown name for volume {volume}")

    volume_path = data_volume_src / f"{kanton.value}_{volume_info.machine_name}" / pdf_name

    return stream(volume_path)


@cachebox.cached(cache=cachebox.LRUCache(maxsize=24))
async def list_all_volumes(
    connection: Connection,
) -> list[str] | None:
    """Lists all volumes based on the kantons and volumes in the database.

    Args:
        connection (aiosqlite.Connection): SQLite connection.
        kanton_short_names (list[str]): List of kanton short names.

    Returns:
        list[str] | None: List of volumes or None.
    """
    volumes = [
        f"{kanton.short_name} {volume.name}"
        for kanton in (await list_kantons(connection)).kantons
        if kanton.docs > 0
        for volume in (await list_volumes_with_editors(connection, kanton.short_name) or [])
    ]
    return sorted(volumes) if volumes else None


async def get_volume_info(connection: Connection, kanton_short_name: str, volume_machine_name: str):
    """Get volume information based on kanton and volume machine name.

    Args:
        connection (Connection): SQLite connection.
        kanton_short_name (str): Kanton short name.
        volume_machine_name (str): Volume machine name.

    Returns:
        Volume: Volume object.

    Raises:
        ValueError: If volume or kanton is not found.
    """
    volumes = await list_volumes_with_editors(connection, kanton_short_name)

    if volumes is None:
        raise ValueError(f"Could not find any volumes for {kanton_short_name}")

    volume = next((v for v in volumes if v.machine_name == volume_machine_name), None)

    if volume is None:
        raise ValueError(f"Could not find volume {volume_machine_name} for {kanton_short_name}")

    return volume
