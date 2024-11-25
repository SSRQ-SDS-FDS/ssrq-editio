from pathlib import Path

import aiosqlite

from ssrq_editio.adapters.db.config import SQL_DATA_DIR
from ssrq_editio.adapters.file import load

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
