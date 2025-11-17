from pathlib import Path

import aiosqlite

from ssrq_editio.adapters.db.config import SQL_DATA_DIR
from ssrq_editio.adapters.db.shared import load_and_execute_query
from ssrq_editio.adapters.file import load
from ssrq_editio.models.volumes import Volume, VolumeMeta


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
                volume.sort_key,
                volume.name,
                volume.kanton,
                volume.title,
                volume.prefix,
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


async def retrieve_volume_metadata(
    connection: aiosqlite.Connection,
    volume_id: str,
    query: Path = SQL_DATA_DIR / "get_volume_meta.sql",
) -> VolumeMeta:
    """Retrieve metadata for a volume.

    Args:
        connection (Connection): An aiosqlite Connection
        volume_id (str): The volume ID
        query (Path): The path to the query file

    Returns:
        VolumeMeta: The metadata for a given volume
    """
    result = await load_and_execute_query(connection, query, volume_id=volume_id)

    if not result:
        raise ValueError(f"Volume {volume_id} not found.")

    return VolumeMeta(**result[0])  # type: ignore
