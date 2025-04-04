import re
from typing import Sequence, cast

from aiosqlite import Connection
from ssrq_utils.lang.display import Lang
from ssrq_utils.uca import uca_complex_sort

from ssrq_editio.adapters.db.entities import (
    search_families,
    search_keywords,
    search_lemmata,
    search_organizations,
    search_persons,
    search_places,
)
from ssrq_editio.models.entities import (
    Entities,
    Entity,
    EntityTypes,
    Family,
    Organization,
    Person,
    Places,
)

ENTITY_ID_PATTERN = re.compile(r"^(key|lem|loc|per|org)(\d{6})$")


async def get_entities(
    connection: Connection,
    entity_type: EntityTypes,
    query: str | None = None,
    occurrence: str | None = None,
) -> Entities:
    """A simple service to retrieve entities from the database. Uses the defined
    db adapters to retrieve the entities based on the entity type and query.

    Args:
        connection (Connection): The database connection.
        entity_type (EntityTypes): The entity type to retrieve.

    Returns:
        Entities: The entities.
    """
    match entity_type:
        case EntityTypes.FAMILIES:
            return await search_families(connection, search=query, occurrence=occurrence)
        case EntityTypes.LEMMATA:
            return await search_lemmata(connection, search=query, occurrence=occurrence)
        case EntityTypes.KEYWORDS:
            return await search_keywords(connection, search=query, occurrence=occurrence)
        case EntityTypes.PLACES:
            return await search_places(connection, search=query, occurrence=occurrence)
        case EntityTypes.PERSONS:
            return await search_persons(connection, search=query, occurrence=occurrence)
        case EntityTypes.ORGANIZATIONS:
            return await search_organizations(connection, search=query, occurrence=occurrence)
        case _:
            raise NotImplementedError


def validate_entity_id(entity_id: str) -> bool:
    """Validate an entity ID.

    Args:
        entity_id (str): The

    Returns:
        bool: True if the entity ID is valid, False otherwise.
    """
    return bool(ENTITY_ID_PATTERN.match(entity_id))


async def resolve_places_for_entities(
    entities: Sequence[Person | Family | Organization], connection: Connection, lang: Lang
) -> tuple[tuple[Entity, Sequence[dict[str, str]] | None], ...]:
    """A service function to resolve and replace place IDs in the 'location' property of each entity with localized place names.

    The resolved names are sorted alphabetically in the specified language.

    ToDo: Potential performance issue. Compare with `resolve_orig_places_for_documents`.

    Args:
        entities (Sequence[Person | Family | Organization]): The entities to resolve the places for.
        connection (Connection): The SQLite connection.
        lang (Lang): The language to sort the places by.

    Returns:
        tuple[tuple[Entity, Sequence[dict[str, str]] | None], ...]: A tuple of entity-place tuples.
    """
    places = cast(Places, await get_entities(connection, EntityTypes.PLACES))

    if len(places.entities) == 0:
        raise ValueError("No places found in the database for resolving.")

    return tuple(
        (
            entity,
            uca_complex_sort(
                [
                    {"id": location, "name": place.get_name_by_lang(lang)}
                    for location in entity.location
                    if (place := places.get_by_id(location))
                ],
                "get",
                ("name",),
            )
            if entity.location
            else None,
        )
        for entity in entities
    )
