from typing import Annotated

from pydantic import BaseModel, BeforeValidator, Field, computed_field, model_validator

from ssrq_editio.models.documents import DocumentType
from ssrq_editio.services.utils import parse_as_list_or_return


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


class VolumeMeta(BaseModel):
    """Contains 'matedata" (means calculated information here)
    about a collection of documents (a volume)."""

    document_types: Annotated[list[DocumentType], BeforeValidator(parse_as_list_or_return)] = Field(
        ..., description="The types of documents in the volume."
    )
    first_year: int | None = Field(
        ...,
        description="The earliest year a document was created. Normalized in the Gregorian calendar.",
    )
    has_facs: bool
    last_year: int | None = Field(
        ...,
        description="The latest year a document was created. Normalized in the Gregorian calendar.",
    )

    @model_validator(mode="after")
    def compare_first_and_last_year(self):
        if (self.first_year and self.last_year) and (self.first_year > self.last_year):
            raise ValueError("The first year must be before the last year.")
        return self


class Volumes(BaseModel):
    volumes: tuple[Volume, ...]
