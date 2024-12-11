from typing import Sequence

from pydantic import BaseModel


class Entity(BaseModel):
    id: str
    de_name: str | None
    fr_name: str | None
    it_name: str | None
    lt_name: str | None
    occurrences: list[str] | None = None


class Entities(BaseModel):
    entities: Sequence[Entity]


class Place(Entity):
    cs_name: str | None
    nl_name: str | None
    pl_name: str | None
    rm_name: str | None


class Places(Entities):
    entities: Sequence[Place]
