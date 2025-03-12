import aiosqlite

from ssrq_editio.adapters.db.kantons import list_kantons


async def list_kanton_abbreviations(connection: aiosqlite.Connection) -> list[str]:
    """A service to list all kanton abbreviations.

    Args:
        connection (aiosqlite.Connection): SQLite connection.

    Returns:
        list[str]: List of kanton abbreviations.
    """
    return [kanton.short_name for kanton in (await list_kantons(connection)).kantons]
