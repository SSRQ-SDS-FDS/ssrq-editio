from pathlib import Path

from pydantic_core import from_json

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
