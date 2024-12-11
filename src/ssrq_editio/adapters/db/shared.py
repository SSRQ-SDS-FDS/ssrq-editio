from aiosqlite import Connection


async def store_batches(
    connection: Connection, batch_size: int, sql_query: str, values: list[tuple]
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
