import re

from aiosqlite import Connection

from ssrq_editio.adapters.db.entities import (
    search_families,
    search_keywords,
    search_lemmata,
    search_organizations,
    search_persons,
    search_places,
)
from ssrq_editio.models.entities import Entities, EntityTypes

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
