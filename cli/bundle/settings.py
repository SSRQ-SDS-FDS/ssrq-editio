from pathlib import Path
import tomllib
from typing import Literal

from cli.config import EDITIO_CONFIG, PROJECT_ROOT
from pydantic import BaseModel


class EditioUrls(BaseModel):
    de: str
    fr: str
    it: str
    en: str


class EditioEnv(BaseModel):
    env: Literal["dev", "prod"]
    cache: bool
    index_prefix: str
    upload: bool
    urls: EditioUrls

    def __str__(self):
        return f"cache: {self.cache}; env: {self.env}; upload: {self.upload}"


def read_settings(cfg_path: Path = EDITIO_CONFIG) -> EditioEnv:
    with open(cfg_path) as cfg:
        config = tomllib.loads(cfg.read())
    return EditioEnv(**config["editio"]["settings"])


def merge_settings(
    settings: EditioEnv, cache: bool, upload: bool, env: str | None
) -> EditioEnv:
    settings.cache = cache
    settings.upload = upload
    if env is not None and env in ["dev", "prod"]:
        settings.env = env  # type: ignore
    return settings


def write_settings_to_env_xml(
    settings: EditioEnv, target_dir: Path, name: str = "env.xml"
):
    with open(target_dir / name, "w") as f:
        f.write(
            f"""<?xml version="1.0" encoding="UTF-8"?>
            <settings>
                <env>{settings.env}</env>
                <cache>{str(settings.cache).lower()}</cache>
                <upload>{str(settings.upload).lower()}</upload>
                <urls>
                    <prefix type="index">{settings.index_prefix}</prefix>
                    {"".join(f'<url lang="{lang}">{url}</url>'
                        for lang, url in settings.urls.model_dump().items())}
                </urls>
            </settings>
            """
        )


write_settings_to_env_xml(read_settings(), PROJECT_ROOT)
