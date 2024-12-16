from pathlib import Path
from typing import AsyncGenerator

import aiosqlite
import httpx
import pytest
from pytest_asyncio_cooperative import Lock  # type: ignore[import]

from ssrq_editio.adapters.db.connection import db_session
from ssrq_editio.adapters.db.kantons import initialize_kanton_data
from ssrq_editio.adapters.db.setup import setup_db
from ssrq_editio.adapters.entities import get_places as fetch_places

db_lock = Lock()


@pytest.fixture(scope="module")
async def entities(httpx_client: httpx.AsyncClient):
    places = await fetch_places(httpx_client, "http://testserver/places.xml")
    return (places,)


@pytest.fixture(scope="function")
async def db_file_lock():
    async with db_lock():
        yield


@pytest.fixture(scope="function")
def db_name():
    return Path("test.sqlite3")


@pytest.fixture(scope="function")
async def db_connection(db_file_lock, db_name) -> AsyncGenerator[aiosqlite.Connection, None]:
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
async def db_setup(db_connection) -> AsyncGenerator[aiosqlite.Connection, None]:
    await setup_db(db_connection)
    yield db_connection


@pytest.fixture(scope="function")
async def db_kanton_data(db_setup) -> AsyncGenerator[aiosqlite.Connection, None]:
    """Setup a database with various data loaded."""
    await initialize_kanton_data(db_setup)
    yield db_setup
