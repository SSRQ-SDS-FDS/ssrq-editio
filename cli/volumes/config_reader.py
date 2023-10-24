from pathlib import Path
import tomllib
from typing import Literal

from cli.config import EDITIO_CONFIG, VOLUMES_SOURCE
from pydantic import BaseModel, computed_field


class Volume(BaseModel):
    name: str
    include: Literal["all", "sources_only"]

    @computed_field
    @property
    def canton(self) -> str:
        return self.name[0:2]

    @computed_field
    @property
    def folder(self) -> Path:
        source = VOLUMES_SOURCE / self.name
        if not source.exists():
            raise ValueError(f"Volume {self.name} does not exist")
        return source


class VolumesConfig(BaseModel):
    volumes: list[Volume]


def read_config() -> VolumesConfig:
    with open(EDITIO_CONFIG) as cfg:
        config = tomllib.loads(cfg.read())
    return VolumesConfig(volumes=config["editio"]["volumes"])
