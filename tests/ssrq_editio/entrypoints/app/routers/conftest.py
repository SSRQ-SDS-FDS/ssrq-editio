from pathlib import Path
from typing import AsyncGenerator

import pytest
from aiosqlite import Connection
from httpx import ASGITransport, AsyncClient
from pytest_asyncio_cooperative import Lock  # type: ignore[import]

from ssrq_editio.adapters.db.connection import db_session
from ssrq_editio.adapters.db.kantons import initialize_kanton_data
from ssrq_editio.adapters.db.setup import setup_db
from ssrq_editio.entrypoints.app.main import app
from ssrq_editio.entrypoints.app.shared.dependencies import db_connection

app_db_lock = Lock()


@pytest.fixture(scope="module")
async def app_db_file_lock():
    async with app_db_lock():
        yield


@pytest.fixture(scope="module")
def app_db_name():
    return Path("app_test.sqlite3")


@pytest.fixture(scope="module")
async def app_db_connection(app_db_file_lock, app_db_name) -> AsyncGenerator[Connection, None]:
    async for connection in db_session(app_db_name, False):
        yield connection
    try:
        app_db_name.unlink()
    except FileNotFoundError:
        pass


@pytest.fixture(scope="module")
async def app_db_setup(app_db_connection) -> AsyncGenerator[Connection, None]:
    await setup_db(app_db_connection)
    await initialize_kanton_data(app_db_connection)
    yield app_db_connection


@pytest.fixture(scope="module")
async def app_client(app_db_setup) -> AsyncGenerator[AsyncClient, None]:
    app.dependency_overrides[db_connection] = lambda: app_db_setup
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        yield client
