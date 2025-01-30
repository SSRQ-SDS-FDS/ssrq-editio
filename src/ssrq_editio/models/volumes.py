from typing import Annotated

from pydantic import BaseModel, BeforeValidator, computed_field


class Volume(BaseModel):
    key: str
    kanton: str
    name: str
    prefix: str
    pdf: str | None
    literature: str | None
    title: str = ""
    editors: Annotated[
        list[str], BeforeValidator(lambda x: x.split(",") if isinstance(x, str) else x)
    ] = []
    docs: int = 0

    @computed_field
    def machine_name(self) -> str:
        return self.name.replace(" ", "_").replace("/", "_")


class Volumes(BaseModel):
    volumes: tuple[Volume, ...]
