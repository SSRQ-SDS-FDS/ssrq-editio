from enum import Enum
from pathlib import Path
from typing import Annotated, Any, Self

from pydantic import BaseModel, BeforeValidator, model_validator
from ssrq_utils.lang.display import Lang

from ssrq_editio.services.utils import parse_as_list_or_return, serialize_value


class DocumentDate(BaseModel):
    de_orig_date: str
    en_orig_date: str
    fr_orig_date: str
    it_orig_date: str
    start_year_of_creation: int | None = None
    end_year_of_creation: int | None = None


class DocumentIdentification(BaseModel):
    idno: str
    is_main: bool
    printed_idno: str
    sort_key: float
    volume_id: str
    uuid: str


class DocumentIdentificationDisplay(BaseModel):
    """A class which holds basic information about a document.

    Intended to be used for displaying the information in the UI.
    """

    idno: str
    kanton: str
    printed_idno: str
    sort_key: float
    volume: str


class DocumentRelations(BaseModel):
    entities: Annotated[
        list[str] | None,
        BeforeValidator(parse_as_list_or_return),
    ] = None
    previous_document: str | None = None
    next_document: str | None = None
    sub_documents: Annotated[
        list[str] | None,
        BeforeValidator(parse_as_list_or_return),
    ] = None


class DocumentSummary(BaseModel):
    content: str
    lang: str


class DocumentComment(BaseModel):
    content: str
    lang: str | None


class DocumentDescriptionHeading(BaseModel):
    idno: str | None = None
    lang: str | None = None
    witnessNumber: str | None = None


class DocumentDescription(BaseModel):
    admin_info: str | None = None
    archival_information: str | None = None
    bibliographic_information: str | None = None
    heading: DocumentDescriptionHeading
    ms_history: str | None = None
    ms_information: str | None = None
    physical_description: str | None = None


class DocumentTitle(BaseModel):
    de_title: str | None = None
    fr_title: str | None = None

    def get_title_by_lang(self, lang: Lang) -> str:
        match (lang, self.de_title, self.fr_title):
            case (Lang.DE, str(), _):
                return self.de_title
            case (Lang.FR, _, str()):
                return self.fr_title
            case _:
                return self.de_title or self.fr_title or ""


class DocumentType(Enum):
    collection = "collection"
    summary = "summary"
    transcript = "transcript"


class Document(DocumentDate, DocumentIdentification, DocumentRelations, DocumentTitle):
    facs: Annotated[
        list[str] | None,
        BeforeValidator(parse_as_list_or_return),
    ]
    orig_place: Annotated[
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


class DocumentFulltext(BaseModel):
    uuid: str
    text: str


class DocumentFulltextResult(Document):
    ft_match: str


class DocumentDisplay(BaseModel):
    """A model representing the infos to be displayed in the UI. The fields
    contain the rendered infos, transformed by XSLT."""

    comment: DocumentComment | None
    descriptions: list[DocumentDescription]
    normalized_transcript: str | None
    summary: DocumentSummary | None
    transcript: str
    type: Annotated[
        DocumentType, BeforeValidator : lambda x: DocumentType(x) if isinstance(x, str) else x
    ]

    @model_validator(mode="after")
    def check_mutually_exclusive_fields(self) -> Self:
        match self.type:
            case DocumentType.collection | DocumentType.summary if (
                self.normalized_transcript is not None
            ):
                raise ValueError(
                    "A normalized transcript is only allowed for documents of type transcript."
                )
            case _:
                return self
