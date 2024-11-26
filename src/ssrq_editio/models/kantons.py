from typing import Annotated

from pydantic import BaseModel, BeforeValidator


class Kanton(BaseModel):
    short_name: str
    de_title: str
    fr_title: str | None
    it_title: str | None
    docs: int
    filenames: Annotated[list[str], BeforeValidator(lambda x: x.split(","))]


class Kantons(BaseModel):
    kantons: tuple[Kanton, ...]
