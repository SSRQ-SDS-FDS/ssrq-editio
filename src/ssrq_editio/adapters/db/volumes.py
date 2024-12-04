from pathlib import Path

import aiosqlite

from ssrq_editio.adapters.db.config import SQL_DATA_DIR
from ssrq_editio.adapters.file import load
from ssrq_editio.models.volumes import Volume


async def initialize_volume_with_editors(
    connection: aiosqlite.Connection,
    volume: Volume,
):
    await initialize_volume_data(connection, volume)
    await initialize_editors(connection, volume)


async def initialize_volume_data(
    connection: aiosqlite.Connection,
    volume: Volume,
    volume_query: Path = SQL_DATA_DIR / "put_volume.sql",
):
    async with connection.cursor() as cursor:
        query = await load(SQL_DATA_DIR, volume_query)
        await cursor.execute(
            query,
            parameters=(
                volume.key,
                volume.name,
                volume.kanton,
                volume.title,
                volume.pdf,
                volume.literature,
            ),
        )
        await connection.commit()


async def initialize_editors(
    connection: aiosqlite.Connection,
    volume: Volume,
    editor_query: Path = SQL_DATA_DIR / "put_editor.sql",
):
    async with connection.cursor() as cursor:
        query = await load(SQL_DATA_DIR, editor_query)
        for editor in volume.editors:
            await cursor.execute(
                query,
                parameters=(editor, volume.key),
            )
            await connection.commit()


async def list_volumes_with_editors(
    connection: aiosqlite.Connection,
    kanton_short_name: str,
    volume_list_query: Path = SQL_DATA_DIR / "get_volumes.sql",
) -> list[Volume] | None:
    async with connection.cursor() as cursor:
        query = await load(SQL_DATA_DIR, volume_list_query)
        await cursor.execute(query, parameters=(kanton_short_name,))
        data = await cursor.fetchall()

        if not data or all(all(value is None for value in row) for row in data):
            # Check if the data is empty or if all values are None
            return None

        return [Volume(**volume) for volume in data]
