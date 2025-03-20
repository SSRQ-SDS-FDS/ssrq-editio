from pathlib import Path
from typing import Iterable

from aiosqlite import Connection, Row

from ssrq_editio.adapters.file import load


async def load_and_execute_query(connection: Connection, query: Path, **kwargs) -> Iterable[Row]:
    """A simple function to load a query from a file and execute it

    Args:
        connection (Connection): An aiosqlite Connection
        query (Path): The path to the query file
        **kwargs: The parameters to pass to the query

    Returns:
        Iterable[Row]: The result of the query
    """
    sql_query = await load(dir=query.parent, name=query.name)

    return await connection.execute_fetchall(sql_query, kwargs)


async def store_batches(
    connection: Connection, batch_size: int, sql_query: str, values: list[tuple | dict]
):
    """
    Stores a list of values in the database by executing a query in batches. This
    should be used for large inserts.

    Args:
        connection (Connection): An aiosqlite Connection
        batch_size (int): The size of the batch
        sql_query (str): The query to execute
        values (list[tuple]): A list of tuples to store in the database
    """
    async with connection.cursor() as cursor:
        for i in range(0, len(values), batch_size):
            await cursor.executemany(sql_query, values[i : i + batch_size])
            await connection.commit()


def replace_wildcard(query: str | None) -> str:
    """A simple function to replace the wildcard character '*' with '%',
    which is used in the database for LIKE queries.

    Args:
        query (str | None): The query string

    Returns:
        str: The query string with '%' instead of '*' or an empty string if None
    """
    if query:
        return query.replace("*", "%")
    return ""
