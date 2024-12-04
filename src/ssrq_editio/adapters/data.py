from pathlib import Path

from pydantic_core import from_json

from ssrq_editio.adapters.file import load
from ssrq_editio.models.volumes import Volume, Volumes


async def load_volume_config(config_src: Path) -> Volumes:
    """Adapter to load the static volume configuration and return it as a Volumes object.

    Args:
        config_src (Path): Path to the volume configuration file.

    Returns:
        Volumes: Volumes object with the configuration data.
    """
    config = from_json(await load(dir=config_src.parent, name=config_src.name))
    return Volumes(volumes=tuple(Volume.model_validate(volume) for volume in config))
