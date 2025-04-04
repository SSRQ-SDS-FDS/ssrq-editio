from random import randint
from uuid import uuid4

import pytest

from ssrq_editio.adapters.db.documents import (
    get_document,
    get_document_infos,
    get_documents,
    initialize_document_data,
)
from ssrq_editio.models.documents import Document, DocumentType


def create_years():
    start_year = randint(700, 1798)
    return (start_year, start_year + randint(1, 80))


@pytest.fixture
def documents():
    documents = []
    for d in range(1, 150):
        years = create_years() if d % 2 == 0 else (None, None)
        documents.append(
            Document(
                uuid=str(uuid4()),
                idno=f"SSRQ-SG-III_4-{d}-1",
                is_main=True,
                sort_key=d,
                de_orig_date="foo",
                en_orig_date="foo",
                fr_orig_date="foo",
                it_orig_date="foo",
                facs=["bar", "baz"] if d % 2 == 0 else None,
                printed_idno=f"SSRQ SG III/4 {d}",
                volume_id="SG_III_4",
                orig_place=["loc000001"],
                de_title="<h3>foo</h3>",
                fr_title=None,
                type=DocumentType.transcript,
                start_year_of_creation=years[0],
                end_year_of_creation=years[1],
            )
        )
    return tuple(documents)


@pytest.mark.anyio
async def test_initialize_document_data(db_volume_data, documents):
    # Smoke test, if query is successful
    await initialize_document_data(documents=documents, connection=db_volume_data)


@pytest.mark.anyio
async def test_get_document_infos(db_volume_data, documents):
    await initialize_document_data(documents=documents, connection=db_volume_data)
    result = await get_document_infos(connection=db_volume_data)
    assert len(result.keys()) == len(documents)
    assert all(uuid in [d.uuid for d in documents] for uuid in result.keys())


@pytest.mark.anyio
async def test_get_documents_filtered_by_range(db_volume_data, documents):
    await initialize_document_data(documents=documents, connection=db_volume_data)
    min_year = min(
        d.start_year_of_creation for d in documents if d.start_year_of_creation is not None
    )
    max_year = max(d.end_year_of_creation for d in documents if d.end_year_of_creation is not None)
    search_result = await get_documents(
        connection=db_volume_data,
        volume_id="SG_III_4",
        range_start=min_year,
        range_end=max_year,
    )
    assert len(search_result) > 0
    for d in search_result:
        if d.end_year_of_creation is not None:
            assert d.end_year_of_creation >= min_year
            assert d.end_year_of_creation <= max_year
        if d.start_year_of_creation is not None:
            assert d.start_year_of_creation <= max_year
            assert d.start_year_of_creation >= min_year
        if d.start_year_of_creation is None and d.end_year_of_creation is None:
            raise pytest.fail(
                f"Document {d.idno} has no start or end year of creation, but is in the range {min_year} - {max_year}"
            )


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("search", "facs", "expected"),
    [(None, False, 149), ("III_4-1-1", False, 1), ("", True, 74)],
)
async def test_get_documents(db_volume_data, documents, search, facs, expected):
    await initialize_document_data(documents=documents, connection=db_volume_data)
    search_result = await get_documents(
        connection=db_volume_data, volume_id="SG_III_4", search=search, facs=facs
    )
    assert len(search_result) == expected


@pytest.mark.anyio
async def test_get_document(db_volume_data, documents):
    await initialize_document_data(documents=documents, connection=db_volume_data)
    for doc in documents:
        result = await get_document(connection=db_volume_data, document_id=doc.idno)
        assert result == doc
        result = await get_document(connection=db_volume_data, document_id=doc.uuid)
        assert result == doc
