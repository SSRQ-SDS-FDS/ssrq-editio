from pathlib import Path

from aiosqlite import Connection

from ssrq_editio.adapters.db.config import SQL_DATA_DIR
from ssrq_editio.adapters.db.shared import store_batches
from ssrq_editio.adapters.file import load
from ssrq_editio.models.entities import Entities, Place, Places


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
        continue


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
            )
            for place in places.entities
        ],
    )


async def search_places(
    connection: Connection, query: Path = SQL_DATA_DIR / "get_places.sql", search: str | None = None
):
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
    async with connection.cursor() as cursor:
        sql_query = await load(dir=query.parent, name=query.name)
        await cursor.execute(sql_query, (search or "",))
        data = await cursor.fetchall()
        return Places(entities=[Place(**place) for place in data])
