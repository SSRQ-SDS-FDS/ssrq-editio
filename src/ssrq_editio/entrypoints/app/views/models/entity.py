from typing import Sequence, cast

from aiosqlite import Connection
from fastapi import Request
from ssrq_utils.lang.display import Lang

from ssrq_editio.adapters.db.documents import get_document_infos
from ssrq_editio.entrypoints.app.views.models.base import ViewContext, ViewModel
from ssrq_editio.models.entities import Entities, Entity, EntityTypes, Family, Organization, Person
from ssrq_editio.services.entities import get_entities, resolve_places_for_entities
from ssrq_editio.services.paginate import create_pages
from ssrq_editio.services.sort import sort_entities_by_name
from ssrq_editio.services.volumes import list_all_volumes


class EntityViewModel(ViewModel):
    """This View Model is used to display a list of entities.."""

    connection: Connection
    entity_type: EntityTypes
    query: str | None
    occurrence: str | None
    current_page: int
    per_page: int

    def __init__(
        self,
        request: Request,
        lang: Lang,
        connection: Connection,
        entity_type: EntityTypes,
        query: str | None,
        occurrence: str | None,
        page: int,
        per_page: int,
    ):
        super().__init__(request, lang)
        self.page = "entity_list.jinja"
        self.template_partial = "entities"
        self.connection = connection
        self.entity_type = entity_type
        self.query = query
        self.occurrence = occurrence
        self.current_page = page
        self.per_page = per_page

    async def create_context(self) -> ViewContext:
        search_result = await self._get_entities()
        document_idnos = await get_document_infos(self.connection)
        volumes = await list_all_volumes(self.connection)
        return ViewContext(
            request=self.request,
            lang=self.lang,
            data={
                "page_title": self._get_title(),
                "page_description": self._get_description(),
                "content": {
                    "current_page": self.current_page,
                    "entities": search_result[1][0] if search_result else None,
                    "entity_type": self.entity_type.value,
                    "idnos": document_idnos,
                    "occurrence": self.occurrence,
                    "pages": search_result[1][1] if search_result else None,
                    "total": search_result[0] if search_result else None,
                    "query": self.query,
                    "volumes": volumes,
                },
            },
            translator=self.translator,
        )

    def _get_title(self) -> str:
        return f"{self.translator.translate(self.lang, 'short_title')} · {self.translator.translate(self.lang, self.entity_type.value)}"

    async def _get_entities(
        self,
    ) -> (
        None
        | tuple[
            int,
            tuple[
                tuple[tuple[Entity, Sequence[dict[str, str]] | None], ...] | Sequence[Entity],
                list[int] | None,
            ],
        ]
    ):
        result: Entities = await get_entities(
            self.connection, self.entity_type, self.query, self.occurrence
        )

        total_hits = len(result.entities)

        if total_hits == 0:
            return None

        paged_entities = create_pages(
            sort_entities_by_name(entities=result.entities, lang=self.lang),
            self.current_page,
            self.per_page,
        )

        match self.entity_type:
            case EntityTypes.FAMILIES | EntityTypes.PERSONS | EntityTypes.ORGANIZATIONS:
                return (
                    total_hits,
                    (
                        await resolve_places_for_entities(
                            cast(Sequence[Person | Organization | Family], paged_entities[0]),
                            self.connection,
                            self.lang,
                        ),
                        paged_entities[1],
                    ),
                )
            case _:
                return total_hits, (
                    paged_entities[0],
                    paged_entities[1],
                )
