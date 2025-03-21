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
    uuid: str
    idno: str
    is_main: bool
    sort_key: float
    de_orig_date: str
    en_orig_date: str
    fr_orig_date: str
    it_orig_date: str
    facs: Annotated[
        list[str] | None,
        BeforeValidator(parse_as_list_or_return),
    ]
    printed_idno: str
    volume_id: str
    orig_place: Annotated[
        list[str] | None,
        BeforeValidator(parse_as_list_or_return),
    ] = None
    de_title: str | None = None
    fr_title: str | None = None
    entities: Annotated[
        list[str] | None,
        BeforeValidator(parse_as_list_or_return),
    ] = None
    sub_documents: Annotated[
        list[str] | None,
        BeforeValidator(parse_as_list_or_return),
    ] = None
    source: Path | None = None
    type: Annotated[
        DocumentType, BeforeValidator : lambda x: DocumentType(x) if isinstance(x, str) else x
    ]

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
