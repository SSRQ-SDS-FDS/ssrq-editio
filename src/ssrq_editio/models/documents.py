from enum import Enum
from pathlib import Path
from typing import Annotated, Any, NamedTuple, Self

from pydantic import BaseModel, BeforeValidator, model_validator

from ssrq_editio.services.utils import parse_as_list_or_return, serialize_value


class DocumentType(Enum):
    collection = "collection"
    summary = "summary"
    transcript = "transcript"


class Document(BaseModel):
    de_orig_date: str
    de_title: str | None = None
    en_orig_date: str
    entities: Annotated[
        list[str] | None,
        BeforeValidator(parse_as_list_or_return),
    ] = None
    facs: Annotated[
        list[str] | None,
        BeforeValidator(parse_as_list_or_return),
    ]
    fr_orig_date: str
    fr_title: str | None = None
    idno: str
    is_main: bool
    it_orig_date: str
    orig_place: Annotated[
        list[str] | None,
        BeforeValidator(parse_as_list_or_return),
    ] = None
    printed_idno: str
    sort_key: float
    source: Path | None = None
    sub_documents: Annotated[
        list[str] | None,
        BeforeValidator(parse_as_list_or_return),
    ] = None
    type: Annotated[
        DocumentType, BeforeValidator : lambda x: DocumentType(x) if isinstance(x, str) else x
    ]
    uuid: str
    volume_id: str
    start_year_of_creation: int | None = None
    end_year_of_creation: int | None = None

    @model_validator(mode="after")
    def check_mutually_exclusive_fields(self) -> Self:
        if not self.is_main and self.sub_documents:
            raise ValueError("Subdocuments are only allowed for main documents.")
        return self

    def model_dump_sqlite(self) -> dict[str, Any]:
        return {k: serialize_value(v) for k, v in self.model_dump().items()}


class DocumentInfo(NamedTuple):
    idno: str
    printed_idno: str
    sort_key: float
    volume: str
    kanton: str
