from pathlib import Path

import aiosqlite

from ssrq_editio.adapters.db.config import SQL_DATA_DIR
from ssrq_editio.adapters.file import load
from ssrq_editio.models.kantons import Kanton, Kantons

# The queries need to be executed in the correct order.
PUT_KANTON_DATA_QUERIES = (
    SQL_DATA_DIR / "put_kantons.sql",
    SQL_DATA_DIR / "put_kanton_images.sql",
)


async def initialize_kanton_data(
    connection: aiosqlite.Connection, table_queries: tuple[Path, ...] = PUT_KANTON_DATA_QUERIES
):
    async with connection.cursor() as cursor:
        for table_query in table_queries:
            query = await load(SQL_DATA_DIR, table_query)
            await cursor.execute(query)
            await connection.commit()


async def list_kantons(
    connection: aiosqlite.Connection, query_file: Path = SQL_DATA_DIR / "get_kantons.sql"
) -> Kantons:
    async with connection.cursor() as cursor:
        query = await load(SQL_DATA_DIR, query_file)
        await cursor.execute(query)
        data = await cursor.fetchall()
        return Kantons(kantons=tuple(Kanton(**kanton) for kanton in data))


async def list_kantons_abbreviations(
    connection: aiosqlite.Connection, query_file: Path = SQL_DATA_DIR / "get_kantons.sql"
) -> list[str]:
    async with connection.cursor() as cursor:
        query = await load(SQL_DATA_DIR, query_file)
        await cursor.execute(query)
        data = await cursor.fetchall()
        return [kanton["short_name"] for kanton in data]
