from pathlib import Path
from typing import AsyncGenerator

import aiosqlite


async def db_session(
    database: str | Path, in_memory: bool = False
) -> AsyncGenerator[aiosqlite.Connection, None]:
    """Create a database session / connection.

    Assumes that a database file should be used
    unless the in_memory flag is set to True. By using
    a context manager, the connection is automatically
    closed when the session ends.

    Args:
        database (str | Path): The database file to use.
        in_memory (bool, optional): Whether to use an in-memory database. Defaults to False.

    Yields:
        aiosqlite.Connection: The database connection.
    """
    match database:
        case Path():
            connection_string = f"{database.as_posix()}"
        case str() if not in_memory:
            connection_string = database
        case _:
            connection_string = ":memory:"

    async with aiosqlite.connect(connection_string) as db:
        # Provide a smarter version of the results. This keeps from having to unpack
        # tuples manually. See https://gist.github.com/petrilli/81511edd88db935d17af0ec271ed950b
        db.row_factory = aiosqlite.Row
        yield db
