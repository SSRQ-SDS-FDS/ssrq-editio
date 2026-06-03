"""Shared data builders for browser-driven E2E tests.

The E2E tests should exercise a realistic application setup without depending on
initialized production data submodules. This module defines a small curated TEI
fixture set, copies those XML files into a temporary production-like
``<volume>/online/*.xml`` directory structure, and builds a temporary SQLite
database through the normal import services.

To add another static E2E document, place the XML fixture below
``tests/ssrq_editio/examples`` and add an ``E2EXmlSource`` entry to
``E2E_XML_SOURCES``. If the document belongs to a new volume, provide a matching
``Volume`` definition there as well. Collection documents need their referenced
subdocuments in the same volume so the existing sort-key based subdocument logic
can resolve them.

The live-data helpers at the bottom intentionally only check for selected files
inside ``src/ssrq_editio/data``. They are used by optional tests and should stay
separate from the stable static fixture set.
"""

from dataclasses import dataclass
from http import HTTPStatus
from pathlib import Path
from shutil import copy2

import httpx
from aiosqlite import Connection

from ssrq_editio.adapters.db.connection import db_session
from ssrq_editio.adapters.db.documents import (
    initialize_document_data,
    initialize_document_fulltext,
)
from ssrq_editio.adapters.db.entities import store_entities
from ssrq_editio.adapters.db.kantons import initialize_kanton_data
from ssrq_editio.adapters.db.setup import setup_db
from ssrq_editio.adapters.db.volumes import initialize_volume_with_editors
from ssrq_editio.adapters.entities import (
    get_families,
    get_keywords,
    get_lemmata,
    get_orgs,
    get_persons,
    get_places,
)
from ssrq_editio.models.volumes import Volume
from ssrq_editio.services.documents import extract_infos_from_xml
from ssrq_editio.services.schema import transpile_schema_to_translations
from ssrq_editio.services.volumes import fill_volume_info_from_xml


@dataclass(frozen=True)
class E2EXmlSource:
    volume: Volume
    source_name: str


E2E_XML_SOURCES: tuple[E2EXmlSource, ...] = (
    E2EXmlSource(
        volume=Volume(
            key="SG_III_4",
            sort_key=1,
            kanton="SG",
            name="III/4",
            prefix="SSRQ",
            title="St. Gallen E2E",
            pdf=None,
            literature=None,
            project_page=None,
            editors=[],
            docs=0,
        ),
        source_name="SSRQ-SG-III_4-63-1.xml",
    ),
    E2EXmlSource(
        volume=Volume(
            key="SG_III_4",
            sort_key=1,
            kanton="SG",
            name="III/4",
            prefix="SSRQ",
            title="St. Gallen E2E",
            pdf=None,
            literature=None,
            project_page=None,
            editors=[],
            docs=0,
        ),
        source_name="SSRQ-SG-III_4-245-1.xml",
    ),
    E2EXmlSource(
        volume=Volume(
            key="NE_1",
            sort_key=1,
            kanton="NE",
            name="1",
            prefix="SDS",
            title="Neuchatel E2E",
            pdf=None,
            literature=None,
            project_page=None,
            editors=[],
            docs=0,
        ),
        source_name="SDS-NE-1-143-1.xml",
    ),
    E2EXmlSource(
        volume=Volume(
            key="ZH_NF_II_11",
            sort_key=1,
            kanton="ZH",
            name="NF II/11",
            prefix="SSRQ",
            title="Zurich E2E",
            pdf=None,
            literature=None,
            project_page=None,
            editors=[],
            docs=0,
        ),
        source_name="SSRQ-ZH-NF_II_11-171-1.xml",
    ),
    E2EXmlSource(
        volume=Volume(
            key="FR_I_2_8",
            sort_key=1,
            kanton="FR",
            name="I/2/8",
            prefix="SSRQ",
            title="Fribourg E2E",
            pdf=None,
            literature=None,
            project_page=None,
            editors=[],
            docs=0,
        ),
        source_name="SSRQ-FR-I_2_8-83.0-1.xml",
    ),
    E2EXmlSource(
        volume=Volume(
            key="FR_I_2_8",
            sort_key=1,
            kanton="FR",
            name="I/2/8",
            prefix="SSRQ",
            title="Fribourg E2E",
            pdf=None,
            literature=None,
            project_page=None,
            editors=[],
            docs=0,
        ),
        source_name="e2e/FR_I_2_8/online/SSRQ-FR-I_2_8-83.1-1.xml",
    ),
    E2EXmlSource(
        volume=Volume(
            key="FR_I_2_8",
            sort_key=1,
            kanton="FR",
            name="I/2/8",
            prefix="SSRQ",
            title="Fribourg E2E",
            pdf=None,
            literature=None,
            project_page=None,
            editors=[],
            docs=0,
        ),
        source_name="e2e/FR_I_2_8/online/SSRQ-FR-I_2_8-83.2-1.xml",
    ),
)


def copy_static_e2e_sources(example_path: Path, data_root: Path) -> dict[str, tuple[Path, ...]]:
    files_by_volume: dict[str, list[Path]] = {}
    for source in E2E_XML_SOURCES:
        volume_online_dir = data_root / source.volume.key / "online"
        volume_online_dir.mkdir(parents=True, exist_ok=True)
        target = volume_online_dir / Path(source.source_name).name
        copy2(example_path / source.source_name, target)
        files_by_volume.setdefault(source.volume.key, []).append(target)

    return {volume: tuple(files) for volume, files in files_by_volume.items()}


async def create_static_e2e_database(
    database: Path,
    example_path: Path,
    data_root: Path,
    transpiled_schema: Path,
) -> None:
    entities = await load_static_entities(example_path)
    async for connection in db_session(database):
        await initialize_static_e2e_database(
            connection=connection,
            example_path=example_path,
            data_root=data_root,
            transpiled_schema=transpiled_schema,
            entities=entities,
        )


async def create_e2e_transpiled_schema(example_path: Path, tmp_path: Path) -> Path:
    return await transpile_schema_to_translations(
        example_path / "schema.xml", tmp_path / "schema-translations.xml"
    )


async def load_static_entities(example_path: Path):
    async def mock_response(request: httpx.Request):
        file_name = Path(request.url.path).name
        file_path = example_path / file_name
        if file_path.exists():
            return httpx.Response(HTTPStatus.OK, content=file_path.read_text())
        return httpx.Response(HTTPStatus.NOT_FOUND)

    async with httpx.AsyncClient(transport=httpx.MockTransport(mock_response)) as httpx_client:
        places = await get_places(httpx_client, "http://testserver/places.xml")
        keywords = await get_keywords(httpx_client, "http://testserver/keywords.xml")
        lemmata = await get_lemmata(httpx_client, "http://testserver/lemmata.xml")
        persons = await get_persons(httpx_client, "http://testserver/persons.xml")
        families = await get_families(httpx_client, "http://testserver/families.xml")
        orgs = await get_orgs(httpx_client, "http://testserver/orgs.xml")
    return places, keywords, lemmata, persons, families, orgs


async def initialize_static_e2e_database(
    connection: Connection,
    example_path: Path,
    data_root: Path,
    transpiled_schema: Path,
    entities,
) -> None:
    await setup_db(connection)
    await initialize_kanton_data(connection)
    await store_entities(entities, connection)

    files_by_volume = copy_static_e2e_sources(example_path, data_root)
    processed_volumes: set[str] = set()
    for source in E2E_XML_SOURCES:
        if source.volume.key in processed_volumes:
            continue

        files = files_by_volume[source.volume.key]
        volume = await fill_volume_info_from_xml(files[0], source.volume)
        await initialize_volume_with_editors(connection, volume)

        extracted = await extract_infos_from_xml(
            xml_src=files,
            volume_id=volume.key,
            transpiled_schema=transpiled_schema,
            parallel=False,
        )
        documents = tuple(document for document, _ in extracted)
        fulltext = tuple(document_fulltext for _, document_fulltext in extracted)

        await initialize_document_data(documents, connection)
        await initialize_document_fulltext(fulltext, connection)
        processed_volumes.add(source.volume.key)


def get_live_e2e_sources(data_root: Path) -> tuple[Path, ...]:
    candidates = (
        data_root / "SG_III_4" / "online" / "SSRQ-SG-III_4-63-1.xml",
        data_root / "SG_III_4" / "online" / "SSRQ-SG-III_4-245-1.xml",
        data_root / "FR_I_2_8" / "online" / "SSRQ-FR-I_2_8-83.0-1.xml",
    )
    return tuple(path for path in candidates if path.exists())


def missing_live_e2e_sources(data_root: Path) -> tuple[Path, ...]:
    candidates = (
        data_root / "SG_III_4" / "online" / "SSRQ-SG-III_4-63-1.xml",
        data_root / "SG_III_4" / "online" / "SSRQ-SG-III_4-245-1.xml",
        data_root / "FR_I_2_8" / "online" / "SSRQ-FR-I_2_8-83.0-1.xml",
    )
    return tuple(path for path in candidates if not path.exists())
