from typing import Annotated

from pydantic import BaseModel, BeforeValidator, Field, computed_field, model_validator
from ssrq_utils.lang.display import Lang

from ssrq_editio.models.documents import DocumentType
from ssrq_editio.services.utils import parse_as_list_or_return

PROJECT_PAGE_BASE = "https://ssrq-sds-fds.ch/"


class Volume(BaseModel):
    key: str
    sort_key: int
    kanton: str
    name: str
    prefix: str
    pdf: str | None
    literature: str | None
    project_page: str | None
    title: str = ""
    editors: Annotated[
        list[str], BeforeValidator(lambda x: x.split(",") if isinstance(x, str) else x)
    ] = []
    docs: int = 0

    @computed_field
    def machine_name(self) -> str:
        return self.name.replace(" ", "_").replace("/", "_")

    def get_project_page_by_lang(self, lang: Lang = Lang.DE) -> str:
        """Retrieve the url of the project page in the specified language.

        Default language is German.

        Args:
            lang (Lang): Language enum object.

        Returns:
            str: URL of project page.
        """
        lang_path = f"{lang.value}/" if lang and lang != Lang.DE else ""
        return f"{PROJECT_PAGE_BASE}{lang_path}{self.project_page}"


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
