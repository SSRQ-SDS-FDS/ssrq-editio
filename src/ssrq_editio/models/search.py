from functools import cached_property

from pydantic import BaseModel, Field, computed_field


class DocumentSearchHit(BaseModel):
    """A compact document representation returned by the full-text search API."""

    uuid: str
    idno: str
    printed_idno: str
    ft_match: str
    keywords: list[str] | None = Field(
        default=None,
        description=(
            "Editor-assigned semantic keywords as entity IDs. Resolve them through the "
            "entity interface; the field may be absent when no keywords were assigned."
        ),
    )


class DocumentSearchResponse(BaseModel):
    """The complete response from the document full-text search."""

    query: str
    results: list[DocumentSearchHit]

    @computed_field  # type: ignore[prop-decorator]
    @cached_property
    def total(self) -> int:
        """Return the number of search hits contained in the response."""
        return len(self.results)
