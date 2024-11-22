import pytest

from ssrq_editio.adapters.db.setup import TABLES, setup_db


@pytest.mark.asyncio_cooperative
async def test_setup_db(db_connection):
    """Test if all tables are created in the database,
    by comparing the len() of `TABLES` with the number of tables."""
    await setup_db(db_connection)
    cursor = await db_connection.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = await cursor.fetchall()
    # We're asserting + 1 here, because SQLITE creates a table called `sqlite_sequence`
    # to track the autoincrement values of the tables.
    assert len(TABLES) + 1 == len(list(tables))
