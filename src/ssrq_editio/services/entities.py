import re
from typing import Sequence, cast

from aiosqlite import Connection
from ssrq_utils.lang.display import Lang
from ssrq_utils.uca import uca_simple_sort

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
    entities: Sequence[Entity], connection: Connection, lang: Lang
) -> tuple[tuple[Entity, list[dict[str, str]] | None], ...]:
    """A service function to resolve and replace place IDs in the 'location' property of each entity with localized place names.

    The resolved names are sorted alphabetically in the specified language.

    ToDo: Potential performance issue. Compare with `resolve_orig_places_for_documents`.

    Args:
        paged_entities (tuple[Sequence[Entity], list[int]]: The entities whose place IDs should be resolved and replaced.
        connection (Connection): The SQLite connection.
        lang (Lang): The language to sort the places by.

    Returns:
        tuple[tuple[Entity, Sequence[str] | None], ...]: A tuple of entities paired with their resolved and localized place names.
    """
    allowed_types = (Family, Person, Organization)
    if all(isinstance(entity, allowed_types) for entity in entities):
        places = cast(Places, await get_entities(connection, EntityTypes.PLACES))
        if len(places.entities) == 0:
            raise ValueError("No places found in the database for resolving.")
        resolved_entities = []
        typed_entities = cast(Sequence[Family], entities)
        for entity in typed_entities:
            resolved_location = {
                place.get_name_by_lang(lang): location
                for location in entity.location or []
                if (place := places.get_by_id(location))
            }
            sorted_location = uca_simple_sort(list(resolved_location.keys()))
            resolved_entities.append(
                (
                    entity,
                    [
                        {"id": resolved_location[location], "name": location}
                        for location in sorted_location
                    ],
                )
            )
        return tuple(resolved_entities)
    else:
        return tuple((entity, None) for entity in entities)
