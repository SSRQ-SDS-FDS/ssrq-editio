from pathlib import Path

import pytest

from ssrq_editio.services.schema import transpile_schema_to_translations


@pytest.mark.anyio
async def test_transpile_schema_to_translations(example_path: Path, tmp_path: Path):
    schema = example_path / "schema.xml"
    translations = await transpile_schema_to_translations(schema, tmp_path / "translations.xml")
    assert translations.exists()
