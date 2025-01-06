from typing import AsyncGenerator

import aiosqlite
import pytest

from ssrq_editio.adapters.db.connection import db_session
from ssrq_editio.adapters.db.kantons import initialize_kanton_data
from ssrq_editio.adapters.db.setup import setup_db


@pytest.fixture(scope="function")
async def db_connection() -> AsyncGenerator[aiosqlite.Connection, None]:
    """This fixtures creates a tmp new database file and yields a connection.

    We don't use a memory based DB here, because we want to mimic the real
    behavior of the application. The fixture will remove the database file
    after the test has run. To avoid race conditions, we use a lock to ensure
    that only one test can access the database file at a time.
    """
    async for connection in db_session("test.sqlite", True):
        yield connection


@pytest.fixture(scope="function")
async def db_setup(db_connection) -> AsyncGenerator[aiosqlite.Connection, None]:
    await setup_db(db_connection)
    yield db_connection


@pytest.fixture(scope="function")
async def db_kanton_data(db_setup) -> AsyncGenerator[aiosqlite.Connection, None]:
    """Setup a database with various data loaded."""
    await initialize_kanton_data(db_setup)
    yield db_setup
