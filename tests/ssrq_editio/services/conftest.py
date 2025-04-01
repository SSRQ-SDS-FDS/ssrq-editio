from pathlib import Path
from typing import AsyncGenerator

import aiosqlite
import pytest

from ssrq_editio.adapters.db.entities import store_entities
from ssrq_editio.adapters.db.setup import setup_db
from ssrq_editio.services.schema import transpile_schema_to_translations


@pytest.fixture
async def transpiled_schema(example_path: Path, tmp_path: Path):
    schema = example_path / "schema.xml"
    return await transpile_schema_to_translations(schema, tmp_path / "translations.xml")


@pytest.fixture
async def db_with_entities(db_connection, entities) -> AsyncGenerator[aiosqlite.Connection, None]:
    await setup_db(db_connection)
    await store_entities(entities, db_connection)
    yield db_connection
