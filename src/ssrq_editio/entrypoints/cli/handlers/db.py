from pathlib import Path
from time import perf_counter

from aiosqlite import Connection

from ssrq_editio.adapters.data import load_register_volume_config, load_volume_config
from ssrq_editio.adapters.db.connection import db_session
from ssrq_editio.adapters.db.documents import initialize_document_data, initialize_document_fulltext
from ssrq_editio.adapters.db.entities import store_entities
from ssrq_editio.adapters.db.kantons import initialize_kanton_data
from ssrq_editio.adapters.db.setup import setup_db
from ssrq_editio.adapters.db.volumes import initialize_volume_with_editors
from ssrq_editio.adapters.entities import fetch_entities
from ssrq_editio.adapters.file import list_dir_content
from ssrq_editio.entrypoints.cli.config import TMP_SCHEMA
from ssrq_editio.models.volumes import Volume, VolumeType
from ssrq_editio.services.documents import extract_infos_from_xml
from ssrq_editio.services.logger import SSRQ_LOGGER
from ssrq_editio.services.schema import transpile_schema_to_translations
from ssrq_editio.services.volumes import create_search_pattern, fill_volume_info_from_xml


async def setup(
    db: str,
    clean: bool,
    config_src: Path,
    data_src: Path,
    schema_src: Path | str,
    parallel: bool,
    profile: bool = False,
):
    SSRQ_LOGGER.info("Preparing the database.")
    setup_start = perf_counter()

    if clean and (db_file := Path(db)).exists():
        db_file.unlink()
        SSRQ_LOGGER.success(f"Removed the existing database file: {db}")

    schema_start = perf_counter()
    transpiled_schema = await transpile_schema_to_translations(schema_src, TMP_SCHEMA)
    schema_seconds = perf_counter() - schema_start

    SSRQ_LOGGER.success("Transpiled the schema to translations.")

    async for session in db_session(db):
        SSRQ_LOGGER.success("Connected to database.")

        await setup_db(session)
        SSRQ_LOGGER.success("Initialized the database with tables and settings.")

        await setup_kantons(session)
        await setup_volumes(
            session, config_src, data_src, transpiled_schema, parallel, profile=profile
        )

        if clean:
            await setup_entities(session)

    if profile:
        SSRQ_LOGGER.info(
            f"Database preparation profile: schema_transpilation={schema_seconds:.3f}s "
            f"total={perf_counter() - setup_start:.3f}s"
        )


async def setup_kantons(connection: Connection):
    await initialize_kanton_data(connection)
    SSRQ_LOGGER.success("Inserted kanton data into the database.")


async def setup_volumes(
    connection: Connection,
    config_src: Path,
    data_src: Path,
    transpiled_schema: Path,
    parallel: bool,
    profile: bool = False,
):
    config = await load_volume_config(config_src)
    SSRQ_LOGGER.success(
        f"Loaded volume configuration and found {len(config.volumes)} volumes to store in DB."
    )

    for volume in config.volumes:
        SSRQ_LOGGER.info(f"Processing volume: {volume.key}")
        if volume.volume_type is VolumeType.REGISTER:
            await setup_register_volume(connection, volume, data_src)
            continue

        files = await list_dir_content(data_src, create_search_pattern(volume))

        if not files:
            SSRQ_LOGGER.warning(f"No documents found for volume: {volume.key}")
            continue

        SSRQ_LOGGER.success(f"Found {len(files)} documents for volume: {volume.key}")

        volume = await fill_volume_info_from_xml(files[0], volume)

        SSRQ_LOGGER.info("Filled volume info from XML.")

        await initialize_volume_with_editors(connection, volume)

        SSRQ_LOGGER.success(f"Inserted volume data for {volume.key} into the database.")

        await setup_documents(
            connection, files, volume.key, transpiled_schema, parallel, profile=profile
        )


async def setup_register_volume(
    connection: Connection, volume: Volume, data_src: Path, config: str = "volume.json"
) -> None:
    """Insert a PDF-only register volume without looking for TEI documents."""
    metadata_path = data_src / volume.key / config
    metadata = await load_register_volume_config(metadata_path)

    if metadata.canton != volume.kanton or metadata.volume != volume.name.replace("/", "."):
        raise ValueError(f"Register metadata in {metadata_path} does not match {volume.key}")
    if volume.pdf is None or not (data_src / volume.key / volume.pdf).is_file():
        raise FileNotFoundError(f"Configured PDF for register volume {volume.key} was not found")

    volume = volume.model_copy(update={"title": metadata.title, "editors": metadata.editors})
    await initialize_volume_with_editors(connection, volume)
    SSRQ_LOGGER.success(f"Inserted register volume data for {volume.key} into the database.")


async def setup_documents(
    connection: Connection,
    files: tuple[Path, ...],
    volume_id: str,
    transpiled_schema: Path,
    parallel: bool,
    profile: bool = False,
):
    SSRQ_LOGGER.info(
        f"Starting to extract infos from {len(files)} XML-documents for »{volume_id}«."
    )

    extraction_start = perf_counter()
    documents = await extract_infos_from_xml(
        xml_src=files,
        volume_id=volume_id,
        transpiled_schema=transpiled_schema,
        parallel=parallel,
    )
    extraction_seconds = perf_counter() - extraction_start

    if profile:
        SSRQ_LOGGER.info(
            f"Document extraction profile for {volume_id}: documents={len(documents)} "
            f"extraction_and_validation={extraction_seconds:.3f}s"
        )

    database_start = perf_counter()
    await initialize_document_data(documents=tuple(d[0] for d in documents), connection=connection)
    document_data_seconds = perf_counter() - database_start
    fulltext_start = perf_counter()
    await initialize_document_fulltext(
        documents=tuple(d[1] for d in documents), connection=connection
    )
    fulltext_seconds = perf_counter() - fulltext_start

    if profile:
        SSRQ_LOGGER.info(
            f"Database write profile for {volume_id}: documents={len(documents)} "
            f"document_data={document_data_seconds:.3f}s fulltext={fulltext_seconds:.3f}s"
        )

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
