import pytest

from ssrq_editio.adapters.db.connection import db_session
from ssrq_editio.adapters.db.kantons import initialize_kanton_data


@pytest.mark.asyncio_cooperative
async def test_initialize_kanton_data(db_setup, db_name):
    """Test if all kantons are inserted into the kantons table."""
    await initialize_kanton_data(db_setup)
    # Close the connection to check if the commit was successful.
    await db_setup.close()
    async for connection in db_session(db_name, False):
        cursor = await connection.execute("SELECT * FROM kantons;")
        rows = await cursor.fetchall()
        assert len(rows) == 23  # type: ignore
