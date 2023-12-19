from pathlib import Path
import tomllib
from typing import Literal
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
    urls: EditioUrls

    def __str__(self):
        return f"cache: {self.cache}; env: {self.env}"


class SourceTargetMap(BaseModel):
    source: Path
    target: Path


class EditioBuildConfig(BaseModel):
    common_ignores: list[Path]
    prod_ignores: list[Path]
    volumes: SourceTargetMap
    misc_data: SourceTargetMap
    css: SourceTargetMap
    expath: Path


class DockerEnvSetting(BaseModel):
    compose_file: str
    user: str
    password: str
    port: str


class DockerSettings(BaseModel):
    dev: DockerEnvSetting


def read_env_settings(cfg_path: Path) -> EditioEnv:
    with open(cfg_path) as cfg:
        config = tomllib.loads(cfg.read())
    return EditioEnv(**config["editio"]["settings"])


def read_build_config(cfg_path: Path) -> EditioBuildConfig:
    with open(cfg_path) as cfg:
        config = tomllib.loads(cfg.read())

    config = config["editio"]["build"]

    for key, value in config.items():
        if isinstance(value, list):
            config[key] = [cfg_path.parent / p for p in value]
        elif isinstance(value, dict):
            config[key] = {k: cfg_path.parent / p for k, p in value.items()}
        else:
            config[key] = cfg_path.parent / value

    return EditioBuildConfig(**config)


def read_docker_settings(cfg_path: Path) -> DockerSettings:
    with open(cfg_path) as cfg:
        config = tomllib.loads(cfg.read())

    return DockerSettings(**config["editio"]["docker"])


def merge_env_settings(settings: EditioEnv, cache: bool, env: str | None) -> EditioEnv:
    settings.cache = cache
    if env is not None and env in ["dev", "prod"]:
        settings.env = env  # type: ignore
    return settings


def write_settings_to_env_xml(settings: EditioEnv, target_dir: Path, name: str = "env.xml"):
    with open(target_dir / name, "w") as f:
        f.write(
            f"""<?xml version="1.0" encoding="UTF-8"?>
            <settings>
                <env>{settings.env}</env>
                <cache>{str(settings.cache).lower()}</cache>
                <urls>
                    <prefix type="index">{settings.index_prefix}</prefix>
                    {"".join(f'<url lang="{lang}">{url}</url>'
                        for lang, url in settings.urls.model_dump().items())}
                </urls>
            </settings>
            """
        )
