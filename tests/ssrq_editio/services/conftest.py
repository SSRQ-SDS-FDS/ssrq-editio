from pathlib import Path

import pytest

from ssrq_editio.services.schema import transpile_schema_to_translations


@pytest.fixture
async def transpiled_schema(example_path: Path, tmp_path: Path):
    schema = example_path / "schema.xml"
    return await transpile_schema_to_translations(schema, tmp_path / "translations.xml")
