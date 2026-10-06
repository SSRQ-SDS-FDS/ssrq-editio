from pathlib import Path

import pytest

from ssrq_editio.adapters.db.kantons import initialize_kanton_data
from ssrq_editio.adapters.db.setup import setup_db
from ssrq_editio.adapters.db.volumes import initialize_volume_with_editors
from ssrq_editio.models.kantons import KantonName
from ssrq_editio.models.volumes import Volume
from ssrq_editio.services.volumes import (
    create_search_pattern,
    fill_volume_info_from_xml,
    stream_volume_pdf,
)


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
async def test_stream_volume_pdf_uses_configured_original_pdf(tmp_path: Path, volume_with_pdfs):
    connection, volume = volume_with_pdfs
    pdf_path = tmp_path / volume.key / "book" / "original.pdf"
    pdf_path.parent.mkdir(parents=True)
    pdf_path.write_bytes(b"original")

    stream = await stream_volume_pdf(KantonName.sg, "III_4", connection, tmp_path)

    assert await read_stream(stream) == b"original"


@pytest.mark.anyio
async def test_stream_volume_pdf_uses_configured_translated_pdf(tmp_path: Path, volume_with_pdfs):
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


@pytest.mark.anyio
async def test_fill_volume_info_collects_collaborateurs_across_documents(tmp_path):
    volume = Volume(
        key="test",
        sort_key=1,
        kanton="ZH",
        name="test",
        prefix="SSRQ",
        pdf=None,
        literature=None,
        project_page=None,
    )
    first = tmp_path / "first.xml"
    first.write_text("""<TEI xmlns="http://www.tei-c.org/ns/1.0"><teiHeader><fileDesc>
        <titleStmt><title>Bandtitel</title><editor><persName>Eva Editor</persName></editor>
        <respStmt><persName>Eva Editor</persName><resp>Transkription</resp></respStmt>
        <respStmt><persName>Zoe Mitarbeit</persName><resp>Qualitätskontrolle</resp>
            <resp>Transkription</resp></respStmt>
        <respStmt><persName>Nur Kontrolle</persName><resp>Qualitätskontrolle</resp>
            <resp>Erstellung Faksimile</resp></respStmt>
        <respStmt><persName>Nur Faksimile</persName><resp>Erstellung Faksimile</resp></respStmt>
        <respStmt><orgName>Eine Organisation</orgName><resp>Transkription</resp></respStmt>
        </titleStmt></fileDesc></teiHeader>
        <text><body><respStmt><persName>Historische Person</persName>
            <resp>Transkription</resp></respStmt></body></text></TEI>""")
    second = tmp_path / "second.xml"
    second.write_text("""<TEI xmlns="http://www.tei-c.org/ns/1.0"><teiHeader><fileDesc>
        <titleStmt><title>Bandtitel</title><editor>Eva Editor</editor>
        <respStmt><persName>  Anna   Mitarbeit </persName><resp>Contrôle de qualité</resp>
            <resp>Encodage XML</resp></respStmt>
        <respStmt><persName>Zoe Mitarbeit</persName><resp>Transkription</resp></respStmt>
        <respStmt><persName>Nur Contrôle</persName><resp>Contrôle de qualité</resp>
            <resp>Création de fac-similé</resp></respStmt>
        <respStmt><persName>Ohne Rolle</persName><resp> </resp></respStmt>
        </titleStmt></fileDesc></teiHeader></TEI>""")

    result = await fill_volume_info_from_xml((first, second), volume)

    assert result.title == "<h3>Bandtitel</h3>"
    assert result.editors == ["Eva Editor"]
    assert result.collaborateurs == ["Anna Mitarbeit", "Zoe Mitarbeit"]

    # A later document must also exclude an editor mentioned earlier as a contributor.
    third = tmp_path / "third.xml"
    third.write_text(
        second.read_text().replace("<editor>Eva Editor</editor>", "<editor>Zoe Mitarbeit</editor>")
    )
    result = await fill_volume_info_from_xml((first, third), volume)
    assert result.collaborateurs == ["Anna Mitarbeit"]


@pytest.mark.anyio
async def test_fill_volume_info_without_collaborateurs(tmp_path):
    volume = Volume(
        key="test",
        sort_key=1,
        kanton="ZH",
        name="test",
        prefix="SSRQ",
        pdf=None,
        literature=None,
        project_page=None,
    )
    source = tmp_path / "empty.xml"
    source.write_text("""<TEI xmlns="http://www.tei-c.org/ns/1.0"><teiHeader><fileDesc>
        <titleStmt><title>Bandtitel</title><editor>Eva Editor</editor>
        <respStmt><persName>Eva Editor</persName><resp>Transkription</resp></respStmt>
        </titleStmt></fileDesc></teiHeader></TEI>""")
    result = await fill_volume_info_from_xml(source, volume)
    assert result.collaborateurs == []
