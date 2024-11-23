from pathlib import Path

from ssrq_editio.adapters.db.connection import db_session
from ssrq_editio.adapters.db.kantons import initialize_kanton_data
from ssrq_editio.adapters.db.setup import setup_db
from ssrq_editio.services.logger import SSRQ_LOGGER


async def setup(db: str, clean: bool):
    SSRQ_LOGGER.info("Preparing the database.")

    if clean and (db_file := Path(db)).exists():
        db_file.unlink()
        SSRQ_LOGGER.success(f"Removed the existing database file: {db}")

    async for session in db_session(db):
        SSRQ_LOGGER.success("Connected to database.")

        await setup_db(session)
        SSRQ_LOGGER.success("Initialized the database with tables and settings.")

        await initialize_kanton_data(session)
        SSRQ_LOGGER.success("Inserted kanton data into the database.")
        await session.commit()
