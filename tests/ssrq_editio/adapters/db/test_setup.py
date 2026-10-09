import json

import pytest

from ssrq_editio.adapters.db.setup import TABLES, setup_db
from ssrq_editio.adapters.db.volumes import list_volumes_with_editors
from ssrq_editio.entrypoints.cli.handlers.db import setup_volumes
from ssrq_editio.models.volumes import VolumeType


@pytest.mark.anyio
async def test_setup_db(db_connection):
    """Test if all tables are created in the database,
    by comparing the len() of `TABLES` with the number of tables."""
    await setup_db(db_connection)
    cursor = await db_connection.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = await cursor.fetchall()
    # We're asserting + 1 here, because SQLITE creates a table called `sqlite_sequence`
    # to track the autoincrement values of the tables.
    assert len(TABLES) <= len(list(tables))


@pytest.mark.anyio
async def test_setup_volumes_loads_register_metadata_without_tei(db_kanton_data, tmp_path):
    config = tmp_path / "data.config.json"
    config.write_text(
        json.dumps(
            [
                {
                    "key": "ZG_1_3",
                    "sort_key": 2,
                    "volume_type": "register",
                    "kanton": "ZG",
                    "name": "1/3",
                    "prefix": "SSRQ",
                    "pdf": "book/ZG_1.3.pdf",
                    "literature": None,
                    "project_page": "/digital/retro/",
                }
            ]
        ),
        encoding="utf-8",
    )
    volume_directory = tmp_path / "data" / "ZG_1_3"
    book_directory = volume_directory / "book"
    book_directory.mkdir(parents=True)
    (volume_directory / "volume.json").write_text(
        json.dumps(
            {
                "canton": "ZG",
                "volume": "1.3",
                "title": "Sachregister und Glossar",
                "editors": ["Peter Stotz"],
            }
        ),
        encoding="utf-8",
    )
    (book_directory / "ZG_1.3.pdf").write_bytes(b"test pdf")

    await setup_volumes(
        db_kanton_data,
        config,
        tmp_path / "data",
        tmp_path / "schema.rng",
        parallel=False,
    )

    volumes = await list_volumes_with_editors(db_kanton_data, "ZG")
    assert volumes is not None
    assert len(volumes) == 1
    assert volumes[0].key == "ZG_1_3"
    assert volumes[0].volume_type is VolumeType.REGISTER
    assert volumes[0].title == "Sachregister und Glossar"
    assert volumes[0].editors == ["Peter Stotz"]
