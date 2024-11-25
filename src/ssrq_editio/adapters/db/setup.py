from pathlib import Path

import aiosqlite

from ssrq_editio.adapters.db.config import SQL_DIR
from ssrq_editio.adapters.file import load

TABLE_DIR = SQL_DIR / "tables"

# We need to define the table queries in the correct order.
TABLES = (
    TABLE_DIR / "kantons.sql",
    TABLE_DIR / "kanton_images.sql",
)


async def setup_db(connection: aiosqlite.Connection, table_queries: tuple[Path, ...] = TABLES):
    async with connection.cursor() as cursor:
        await setup_foreign_key(cursor)
        await setup_tables(cursor, table_queries)
    await connection.commit()


async def setup_foreign_key(cursor: aiosqlite.Cursor) -> aiosqlite.Cursor:
    """Enable foreign key constraints.

    Per default, foreign key constraints are disabled in SQLite.
    So we need to enable them explicitly.

    Args:
        cursor (aiosqlite.Cursor): The database cursor.
    """

    return await cursor.execute("PRAGMA foreign_keys = ON")


async def setup_tables(
    cursor: aiosqlite.Cursor, table_queries: tuple[Path, ...]
) -> aiosqlite.Cursor:
    """Load all table queries and execute them.

    Args:
        cursor (aiosqlite.Cursor): The database cursor.
        table_queries (tuple[Path, ...], optional): The table queries to load.
            Defaults to TABLES.

    Returns:
        aiosqlite.Cursor: The database cursor.
    """
    for table_query in table_queries:
        query = await load(TABLE_DIR, table_query)
        await cursor.execute(query)
    return cursor
