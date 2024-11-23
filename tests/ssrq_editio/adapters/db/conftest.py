from pathlib import Path

import pytest
from pytest_asyncio_cooperative import Lock  # type: ignore[import]

from ssrq_editio.adapters.db.connection import db_session
from ssrq_editio.adapters.db.setup import setup_db

db_lock = Lock()


@pytest.fixture(scope="function")
async def db_file_lock():
    async with db_lock():
        yield


@pytest.fixture(scope="function")
def db_name():
    return Path("test.sqlite3")


@pytest.fixture(scope="function")
async def db_connection(db_file_lock, db_name):
    """This fixtures creates a tmp new database file and yields a connection.

    We don't use a memory based DB here, because we want to mimic the real
    behavior of the application. The fixture will remove the database file
    after the test has run. To avoid race conditions, we use a lock to ensure
    that only one test can access the database file at a time.
    """
    async for connection in db_session(db_name, False):
        yield connection
    try:
        db_name.unlink()
    except FileNotFoundError:
        pass


@pytest.fixture(scope="function")
async def db_setup(db_connection):
    await setup_db(db_connection)
    yield db_connection
