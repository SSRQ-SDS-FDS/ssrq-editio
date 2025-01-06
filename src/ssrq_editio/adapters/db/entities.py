import json
from pathlib import Path
from typing import Type, TypeVar

from aiosqlite import Connection

from ssrq_editio.adapters.db.config import SQL_DATA_DIR
from ssrq_editio.adapters.db.shared import store_batches
from ssrq_editio.adapters.file import load
from ssrq_editio.models.entities import (
    Entities,
    Entity,
    EntityTypes,
    Keyword,
    Keywords,
    Lemma,
    Lemmata,
    Person,
    Persons,
    Place,
    Places,
)

__all__ = [
    "count_entities",
    "search_keywords",
    "search_lemmata",
    "search_persons",
    "search_places",
    "store_entities",
]

T = TypeVar("T", bound=Entity)


async def count_entities(connection: Connection, table: EntityTypes) -> int:
    """Counts the number of entities in the database in a specific table.

    Args:
        connection (Connection): An aiosqlite Connection
        table (EntityTypes): An EntityTypes object, which corresponds to a table.

    Returns:
        int: The number of entities in the table.
    """
    if not isinstance(table, EntityTypes):
        # TypeGuard, which will prevent SQL injection attacks
        raise ValueError("The table must be an instance of Entities.")

    async with connection.cursor() as cursor:
        await cursor.execute(f"SELECT COUNT(*) FROM {table.value}")
        data = await cursor.fetchone()
        return int(data[0]) if data else 0


async def list_entity_ids(connection: Connection, table: EntityTypes) -> list[str]:
    """Lists the IDs of the entities in the database in a specific table.

    Args:
        connection (Connection): An aiosqlite Connection
        table (EntityTypes): An EntityTypes object, which corresponds to a table.

    Returns:
        list[str]: A list of entity IDs.
    """
    if not isinstance(table, EntityTypes):
        raise ValueError("The table must be an instance of Entities.")

    async with connection.cursor() as cursor:
        await cursor.execute(f"SELECT id FROM {table.value}")
        data = await cursor.fetchall()
        return [item[0] for item in data]


async def store_entities(
    entities: tuple[Entities, ...], connection: Connection, batch_size: int = 256
):
    """Stores entities in the database by mapping
    the entities to the appropriate store function, which
    uses a query to store the entities in the database.

    Args:
        entities (tuple[Entities, ...]): A tuple of Entities
        connection (Connection): An aiosqlite Connection
        batch_size (int): The size of the batch. Defaults to 256.
    """
    for entity in entities:
        if isinstance(entity, Places):
            await _store_places(entity, connection, batch_size)
        elif isinstance(entity, Keywords):
            await _store_keywords(entity, connection, batch_size)
        elif isinstance(entity, Lemmata):
            await _store_lemmata(entity, connection, batch_size)
        elif isinstance(entity, Persons):
            await _store_persons(entity, connection, batch_size)
        continue


async def _store_persons(
    persons: Persons,
    connection: Connection,
    batch_size: int,
    query: Path = SQL_DATA_DIR / "put_person.sql",
):
    """Stores persons in the database.

    Args:
        persons (Persons): A Places object
        connection (Connection): An aiosqlite Connection
        batch_size (int): The size of the batch
        query (str): The query to execute. Defaults to "put_person.sql".
    """
    sql_query = await load(dir=query.parent, name=query.name)
    await store_batches(
        connection,
        batch_size,
        sql_query,
        [
            (
                person.id,
                person.de_name,
                person.fr_name,
                person.it_name,
                person.lt_name,
                person.rm_name,
                person.de_surname,
                person.fr_surname,
                person.it_surname,
                person.lt_surname,
                person.rm_surname,
                person.sex,
                person.first_mention,
                person.last_mention,
                person.birth,
                person.death,
            )
            for person in persons.entities
        ],
    )


async def _store_places(
    places: Places,
    connection: Connection,
    batch_size: int,
    query: Path = SQL_DATA_DIR / "put_place.sql",
):
    """Stores places in the database.

    Args:
        places (Places): A Places object
        connection (Connection): An aiosqlite Connection
        batch_size (int): The size of the batch
        query (str): The query to execute. Defaults to "put_place.sql".
    """
    sql_query = await load(dir=query.parent, name=query.name)
    await store_batches(
        connection,
        batch_size,
        sql_query,
        [
            (
                place.id,
                place.cs_name,
                place.de_name,
                place.fr_name,
                place.it_name,
                place.lt_name,
                place.nl_name,
                place.pl_name,
                place.rm_name,
                json.dumps(place.de_place_types),
                json.dumps(place.fr_place_types),
            )
            for place in places.entities
        ],
    )


async def _store_keywords(
    terms: Keywords,
    connection: Connection,
    batch_size: int,
    query: Path = SQL_DATA_DIR / "put_keywords.sql",
):
    """Stores keywords in the database.

    Args:
        terms (Keywords): A Lemmata or Keywords object
        connection (Connection): An aiosqlite Connection
        batch_size (int): The size of the batch
        query (str): The query to execute. Defaults to "put_terms.sql".
    """
    sql_query = await load(dir=query.parent, name=query.name)
    await store_batches(
        connection,
        batch_size,
        sql_query,
        [
            (
                term.id,
                term.de_name,
                term.fr_name,
                term.it_name,
                term.lt_name,
                term.de_definition,
                term.fr_definition,
                term.it_definition,
            )
            for term in terms.entities
        ],
    )


async def _store_lemmata(
    terms: Lemmata,
    connection: Connection,
    batch_size: int,
    query: Path = SQL_DATA_DIR / "put_lemmata.sql",
):
    """Stores lemmata in the database.

    Args:
        terms (Lemmata): A Lemmata or Keywords object
        connection (Connection): An aiosqlite Connection
        batch_size (int): The size of the batch
        query (str): The query to execute. Defaults to "put_terms.sql".
    """
    sql_query = await load(dir=query.parent, name=query.name)
    await store_batches(
        connection,
        batch_size,
        sql_query,
        [
            (
                term.id,
                term.de_name,
                term.fr_name,
                term.it_name,
                term.lt_name,
                term.rm_name,
                term.de_definition,
                term.fr_definition,
                term.it_definition,
            )
            for term in terms.entities
        ],
    )


async def search_lemmata(
    connection: Connection,
    query: Path = SQL_DATA_DIR / "get_lemmata.sql",
    search: str | None = None,
) -> Lemmata:
    """Searches for lemmata in the database.

    If no query-string is provided, all lemmata are returned, because
    the query is executed with an empty string.

    Args:
        connection (Connection): An aiosqlite Connection
        query (Path): The query to execute. Defaults to "get_terms.sql".
        search (str | None): A query-string. Defaults to None.

    Returns:
        Lemmata: A Lemmata object
    """
    return Lemmata(
        entities=list(
            await _search_entities(
                connection, Lemma, await load(dir=query.parent, name=query.name), search
            ),
        )
    )


async def search_keywords(
    connection: Connection,
    query: Path = SQL_DATA_DIR / "get_keywords.sql",
    search: str | None = None,
) -> Keywords:
    """Searches for keywords in the database.

    If no query-string is provided, all keywords are returned, because
    the query is executed with an empty string.

    Args:
        connection (Connection): An aiosqlite Connection
        query (Path): The query to execute. Defaults to "get_terms.sql".
        search (str | None): A query-string. Defaults to None.

    Returns:
        Keywords: A Keywords object
    """
    return Keywords(
        entities=list(
            await _search_entities(
                connection, Keyword, await load(dir=query.parent, name=query.name), search
            )
        )
    )


async def search_persons(
    connection: Connection,
    query: Path = SQL_DATA_DIR / "get_persons.sql",
    search: str | None = None,
) -> Persons:
    """Searches for persons in the database.

    If no query-string is provided, all places are returned, because
    the query is executed with an empty string.

    Args:
        connection (Connection): An aiosqlite Connection
        query (Path): The query to execute. Defaults to "get_persons.sql".
        search (str | None): A query-string. Defaults to None.

    Returns:
        Persons: A Persons object
    """
    return Persons(
        entities=await _search_entities(
            connection, Person, await load(dir=query.parent, name=query.name), search
        )
    )


async def search_places(
    connection: Connection, query: Path = SQL_DATA_DIR / "get_places.sql", search: str | None = None
) -> Places:
    """Searches for places in the database.

    If no query-string is provided, all places are returned, because
    the query is executed with an empty string.

    Args:
        connection (Connection): An aiosqlite Connection
        query (Path): The query to execute. Defaults to "get_places.sql".
        search (str | None): A query-string. Defaults to None.

    Returns:
        Places: A Places object
    """
    return Places(
        entities=await _search_entities(
            connection, Place, await load(dir=query.parent, name=query.name), search
        )
    )


async def _search_entities(
    connection: Connection,
    entity_type: Type[T],
    sql_query: str,
    search: str | None = None,
) -> list[T]:
    async with connection.cursor() as cursor:
        await cursor.execute(sql_query, {"search": search or ""})
        data = await cursor.fetchall()
        return [entity_type(**item) for item in data]
