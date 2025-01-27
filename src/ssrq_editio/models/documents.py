from typing import Annotated, Any

from pydantic import BaseModel, BeforeValidator
from pydantic_core import from_json, to_json


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
    volume_id: str
    orig_place: str | None
    de_title: str | None = None
    fr_title: str | None = None
    entities: Annotated[
        list[str] | None,
        BeforeValidator(lambda x: x if isinstance(x, list) or x is None else from_json(x)),
    ] = None

    def model_dump_sqlite(self) -> dict[str, Any]:
        return {
            k: v if not isinstance(v, list) else to_json(v) for k, v in self.model_dump().items()
        }
