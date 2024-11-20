from typing import AsyncGenerator

import aiosqlite
import pytest

from ssrq_editio.services.db.connection import db_session


@pytest.mark.asyncio_cooperative
async def test_db_session():
    """Test creating a database session / connection
    is possible using an in-memory database."""
    session = db_session("", True)
    assert session is not None
    assert isinstance(session, AsyncGenerator)

    async for db in session:
        cursor = await db.execute("SELECT 1")
        assert isinstance(cursor, aiosqlite.Cursor)
        row = await cursor.fetchone()
        assert row is not None
        assert row[0] == 1
