from pathlib import Path

from aiosqlite import Connection

from ssrq_editio.adapters.data import load_volume_config
from ssrq_editio.adapters.db.connection import db_session
from ssrq_editio.adapters.db.documents import initialize_document_data
from ssrq_editio.adapters.db.entities import store_entities
from ssrq_editio.adapters.db.kantons import initialize_kanton_data
from ssrq_editio.adapters.db.setup import setup_db
from ssrq_editio.adapters.db.volumes import initialize_volume_with_editors
from ssrq_editio.adapters.entities import fetch_entities
from ssrq_editio.adapters.file import list_dir_content
from ssrq_editio.entrypoints.cli.config import TMP_SCHEMA
from ssrq_editio.services.documents import extract_infos_from_xml
from ssrq_editio.services.logger import SSRQ_LOGGER
from ssrq_editio.services.schema import transpile_schema_to_translations
from ssrq_editio.services.volumes import create_search_pattern, fill_volume_info_from_xml


async def setup(
    db: str, clean: bool, config_src: Path, data_src: Path, schema_src: Path | str, parallel: bool
):
    SSRQ_LOGGER.info("Preparing the database.")

    if clean and (db_file := Path(db)).exists():
        db_file.unlink()
        SSRQ_LOGGER.success(f"Removed the existing database file: {db}")

    transpiled_schema = await transpile_schema_to_translations(schema_src, TMP_SCHEMA)

    SSRQ_LOGGER.success("Transpiled the schema to translations.")

    async for session in db_session(db):
        SSRQ_LOGGER.success("Connected to database.")

        await setup_db(session)
        SSRQ_LOGGER.success("Initialized the database with tables and settings.")

        await setup_kantons(session)
        await setup_volumes(session, config_src, data_src, transpiled_schema, parallel)

        if clean:
            await setup_entities(session)


async def setup_kantons(connection: Connection):
    await initialize_kanton_data(connection)
    SSRQ_LOGGER.success("Inserted kanton data into the database.")


async def setup_volumes(
    connection: Connection,
    config_src: Path,
    data_src: Path,
    transpiled_schema: Path,
    parallel: bool,
):
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

        await setup_documents(connection, files, volume.key, transpiled_schema, parallel)


async def setup_documents(
    connection: Connection,
    files: tuple[Path, ...],
    volume_id: str,
    transpiled_schema: Path,
    parallel: bool,
):
    SSRQ_LOGGER.info(
        f"Starting to extract infos from {len(files)} XML-documents for »{volume_id}«."
    )

    documents = await extract_infos_from_xml(
        xml_src=files, volume_id=volume_id, transpiled_schema=transpiled_schema, parallel=parallel
    )

    await initialize_document_data(documents=documents, connection=connection)

    SSRQ_LOGGER.success(
        f"Extracted and inserted document data for »{volume_id}« into the database."
    )


async def setup_entities(connection: Connection, prune: bool = False):
    SSRQ_LOGGER.info(
        "Starting to fetch entities from the provided API-endpoints (may take a while)..."
    )
    entities = await fetch_entities()
    SSRQ_LOGGER.success("Fetched entity-data, starting DB-insert..")
    await store_entities(entities=entities, connection=connection, prune=prune)
    SSRQ_LOGGER.success("Inserted entities into the database.")
