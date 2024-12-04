from typing import Annotated

from pydantic import BaseModel, BeforeValidator


class Volume(BaseModel):
    key: str
    kanton: str
    name: str
    pdf: str | None
    literature: str | None
    title: str = ""
    editors: Annotated[
        list[str], BeforeValidator(lambda x: x.split(",") if isinstance(x, str) else x)
    ] = []


class Volumes(BaseModel):
    volumes: tuple[Volume, ...]
