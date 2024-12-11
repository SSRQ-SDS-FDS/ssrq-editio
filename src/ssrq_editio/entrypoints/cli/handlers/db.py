from pathlib import Path

from aiosqlite import Connection

from ssrq_editio.adapters.data import load_volume_config
from ssrq_editio.adapters.db.connection import db_session
from ssrq_editio.adapters.db.entities import store_entities
from ssrq_editio.adapters.db.kantons import initialize_kanton_data
from ssrq_editio.adapters.db.setup import setup_db
from ssrq_editio.adapters.db.volumes import initialize_volume_with_editors
from ssrq_editio.adapters.entities import fetch_entities
from ssrq_editio.adapters.file import list_dir_content
from ssrq_editio.services.logger import SSRQ_LOGGER
from ssrq_editio.services.volumes import create_search_pattern, fill_volume_info_from_xml


async def setup(db: str, clean: bool, config_src: Path, data_src: Path):
    SSRQ_LOGGER.info("Preparing the database.")

    if clean and (db_file := Path(db)).exists():
        db_file.unlink()
        SSRQ_LOGGER.success(f"Removed the existing database file: {db}")

    async for session in db_session(db):
        SSRQ_LOGGER.success("Connected to database.")

        await setup_db(session)
        SSRQ_LOGGER.success("Initialized the database with tables and settings.")

        await setup_kantons(session)
        await setup_volumes(session, config_src, data_src)

        if clean:
            await setup_entities(session)


async def setup_kantons(connection: Connection):
    await initialize_kanton_data(connection)
    SSRQ_LOGGER.success("Inserted kanton data into the database.")


async def setup_volumes(connection: Connection, config_src: Path, data_src: Path):
    config = await load_volume_config(config_src)
    SSRQ_LOGGER.success(
        f"Loaded volume configuration and found {len(config.volumes)} volumes to store in DB."
    )

    for volume in config.volumes:
        SSRQ_LOGGER.info(f"Processing volume: {volume.key}")
        files = await list_dir_content(data_src, create_search_pattern(volume))

        if not files:
            SSRQ_LOGGER.warning(f"No documents found for volume: {volume.key}")
            continue

        SSRQ_LOGGER.success(f"Found {len(files)} documents for volume: {volume.key}")

        volume = await fill_volume_info_from_xml(files[0], volume)

        SSRQ_LOGGER.info("Filled volume info from XML.")

        await initialize_volume_with_editors(connection, volume)

        SSRQ_LOGGER.success(f"Inserted volume data for {volume.key} into the database.")


async def setup_entities(connection: Connection):
    SSRQ_LOGGER.info("Starting to fetch entities from the provided API-endpoints...")
    entities = await fetch_entities()
    SSRQ_LOGGER.success("Fetched entity-data, starting DB-insert..")
    await store_entities(entities, connection)
    SSRQ_LOGGER.success("Inserted entities into the database.")
