from typing import AsyncGenerator

import pytest
from aiosqlite import Connection
from httpx import ASGITransport, AsyncClient

from ssrq_editio.adapters.db.connection import db_session
from ssrq_editio.adapters.db.entities import store_entities
from ssrq_editio.adapters.db.kantons import initialize_kanton_data
from ssrq_editio.adapters.db.setup import setup_db
from ssrq_editio.adapters.db.volumes import initialize_volume_with_editors
from ssrq_editio.entrypoints.app.main import app
from ssrq_editio.entrypoints.app.shared.dependencies import db_connection
from ssrq_editio.models.volumes import Volume

TEST_VOLUMES = [
    Volume(
        key="SG_III_4",
        kanton="SG",
        name="III 4",
        prefix="SSRQ",
        title="test",
        pdf=None,
        literature=None,
        editors=["Max Mustermann"],
        docs=0,
    )
]


@pytest.fixture(scope="module")
async def app_db_connection() -> AsyncGenerator[Connection, None]:
    async for connection in db_session("app_test.sqlite", True):
        yield connection


@pytest.fixture(scope="module")
async def app_db_setup(app_db_connection, entities) -> AsyncGenerator[Connection, None]:
    await setup_db(app_db_connection)
    await initialize_kanton_data(app_db_connection)
    await initialize_volume_with_editors(app_db_connection, TEST_VOLUMES[0])
    await store_entities(entities, app_db_connection)
    yield app_db_connection


@pytest.fixture(scope="function")
async def app_client(app_db_setup) -> AsyncGenerator[AsyncClient, None]:
    app.dependency_overrides[db_connection] = lambda: app_db_setup
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        yield client
