from typing import Annotated

from pydantic import BaseModel, BeforeValidator
from pydantic_core import from_json


class Document(BaseModel):
    uuid: str
    idno: str
    is_main: bool
    sort_key: int
    de_orig_date: str
    en_orig_date: str
    fr_orig_date: str
    it_orig_date: str
    facs: Annotated[
        list[str] | None,
        BeforeValidator(lambda x: x if isinstance(x, list) or x is None else from_json(x)),
    ]
    printed_idno: str
    volume_id: int
    orig_place: str | None
    de_title: str | None = None
    fr_title: str | None = None
