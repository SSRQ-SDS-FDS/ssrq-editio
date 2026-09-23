from pathlib import Path

import pytest

from ssrq_editio.adapters.db.kantons import initialize_kanton_data
from ssrq_editio.adapters.db.setup import setup_db
from ssrq_editio.adapters.db.volumes import initialize_volume_with_editors
from ssrq_editio.models.kantons import KantonName
from ssrq_editio.models.volumes import Volume
from ssrq_editio.services.volumes import create_search_pattern, stream_volume_pdf


def test_create_search_pattern():
    volume = Volume(
        key="foo",
        sort_key=1,
        name="foo bar",
        title="bar",
        kanton="baz",
        literature=None,
        project_page=None,
        pdf=None,
        editors=[],
        prefix="SSRQ",
    )
    result = create_search_pattern(volume)
    assert result == "foo/online/*-1.xml"


async def read_stream(stream):
    return b"".join([chunk async for chunk in stream])


@pytest.fixture
async def volume_with_pdfs(db_connection):
    await setup_db(db_connection)
    await initialize_kanton_data(db_connection)
    volume = Volume(
        key="SG_III_4",
        sort_key=1,
        kanton="SG",
        name="III 4",
        prefix="SSRQ",
        title="Test volume",
        pdf="book/original.pdf",
        translated_pdf="book/translation.pdf",
        literature=None,
        project_page=None,
        editors=["Test Editor"],
    )
    await initialize_volume_with_editors(db_connection, volume)
    return db_connection, volume


@pytest.mark.anyio
async def test_stream_volume_pdf_uses_configured_original_pdf(
    tmp_path: Path, volume_with_pdfs
):
    connection, volume = volume_with_pdfs
    pdf_path = tmp_path / volume.key / "book" / "original.pdf"
    pdf_path.parent.mkdir(parents=True)
    pdf_path.write_bytes(b"original")

    stream = await stream_volume_pdf(KantonName.sg, "III_4", connection, tmp_path)

    assert await read_stream(stream) == b"original"


@pytest.mark.anyio
async def test_stream_volume_pdf_uses_configured_translated_pdf(
    tmp_path: Path, volume_with_pdfs
):
    connection, volume = volume_with_pdfs
    pdf_path = tmp_path / volume.key / "book" / "translation.pdf"
    pdf_path.parent.mkdir(parents=True)
    pdf_path.write_bytes(b"translation")

    stream = await stream_volume_pdf(
        KantonName.sg, "III_4", connection, tmp_path, suffix="-translated"
    )

    assert await read_stream(stream) == b"translation"


@pytest.mark.anyio
async def test_stream_volume_pdf_rejects_unknown_suffix(tmp_path: Path, volume_with_pdfs):
    connection, _ = volume_with_pdfs

    with pytest.raises(ValueError, match="Unknown name for volume III_4"):
        await stream_volume_pdf(KantonName.sg, "III_4", connection, tmp_path, suffix="other")
