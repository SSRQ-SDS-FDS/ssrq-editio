import pytest

from ssrq_editio.adapters.db.connection import db_session


@pytest.fixture(scope="function")
async def db_connection():
    async for connection in db_session("", True):
        yield connection
