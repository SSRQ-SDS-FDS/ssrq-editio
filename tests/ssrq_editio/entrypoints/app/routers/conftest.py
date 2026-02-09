from typing import AsyncGenerator

import pytest
from aiosqlite import Connection
from httpx import ASGITransport, AsyncClient
from ssrq_utils.idno.model import IDNO

from ssrq_editio.adapters.db.connection import db_session
from ssrq_editio.adapters.db.documents import initialize_document_data
from ssrq_editio.adapters.db.entities import store_entities
from ssrq_editio.adapters.db.kantons import initialize_kanton_data
from ssrq_editio.adapters.db.setup import setup_db
from ssrq_editio.adapters.db.volumes import initialize_volume_with_editors
from ssrq_editio.entrypoints.app.main import app
from ssrq_editio.entrypoints.app.shared.dependencies import db_connection
from ssrq_editio.models.documents import (
    Document,
    DocumentType,
)
from ssrq_editio.models.volumes import Volume

TEST_VOLUMES = [
    Volume(
        key="SG_III_4",
        sort_key=1,
        kanton="SG",
        name="III 4",
        prefix="SSRQ",
        title="test",
        pdf=None,
        literature=None,
        project_page=None,
        editors=["Max Mustermann"],
        docs=0,
    )
]

TEST_DOCUMENTS = (
    Document(
        uuid="d56f1ce8-cec9-49ed-b54b-09f397adc2d8",
        idno="SSRQ-SG-III_4-1-1",
        is_main=True,
        sort_key=IDNO.model_validate_string("SSRQ-SG-III_4-1-1").normalized_sort_key,
        de_orig_date='<span class="tei-origDate">1473 April 26 a. S.</span>',
        en_orig_date='<span class="tei-origDate">1473 April 26 O.S.</span>',
        fr_orig_date='<span class="tei-origDate">1473 avril 26 a. s.</span>',
        it_orig_date='<span class="tei-origDate">1473 aprile 26 v. s.</span>',
        facs=["OGA_Gams_Nr_5_r", "OGA_Gams_Nr_5_v"],
        printed_idno="SSRQ SG III/4 1/1",
        volume_id="SG_III_4",
        orig_place=["loc000001"],
        de_title="foo",
        fr_title=None,
        entities=[
            "per031589",
            "loc000001",
            "key000001",
            "lem000001",
            "org000001",
        ],
        type=DocumentType.transcript,
        start_year_of_creation=1473,
        end_year_of_creation=None,
    ),
)


@pytest.fixture(scope="module")
async def app_db_connection() -> AsyncGenerator[Connection, None]:
    async for connection in db_session("app_test.sqlite", True):
        yield connection


@pytest.fixture(scope="module")
async def app_db_setup(app_db_connection, entities) -> AsyncGenerator[Connection, None]:
    await setup_db(app_db_connection)
    await initialize_kanton_data(app_db_connection)
    await initialize_volume_with_editors(app_db_connection, TEST_VOLUMES[0])
    await initialize_document_data(TEST_DOCUMENTS, app_db_connection)
    await store_entities(entities, app_db_connection)
    yield app_db_connection


@pytest.fixture(scope="function")
async def app_client(app_db_setup) -> AsyncGenerator[AsyncClient, None]:
    app.dependency_overrides[db_connection] = lambda: app_db_setup
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        yield client
