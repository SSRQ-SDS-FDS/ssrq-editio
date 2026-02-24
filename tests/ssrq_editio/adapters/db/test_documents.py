from random import randint
from uuid import uuid4

import pytest
from ssrq_utils.idno.model import IDNO

from ssrq_editio.adapters.db.documents import (
    get_document,
    get_document_infos,
    get_documents,
    get_documents_by_ft,
    get_sub_documents,
    initialize_document_data,
    initialize_document_fulltext,
)
from ssrq_editio.models.documents import Document, DocumentFulltext, DocumentType


def create_years():
    start_year = randint(700, 1798)
    return (start_year, start_year + randint(1, 80))


@pytest.fixture
def documents():
    documents = []
    max_range = 150
    for d in range(1, max_range):
        years = create_years() if d % 2 == 0 else (None, None)
        documents.append(
            Document(
                uuid=str(uuid4()),
                idno=f"SSRQ-SG-III_4-{d}-1",
                is_main=True,
                sort_key=IDNO.model_validate_string(f"SSRQ-SG-III_4-{d}-1").normalized_sort_key,
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
                previous_document=f"SSRQ-SG-III_4-{d - 1}-1" if d > 1 else None,
                next_document=f"SSRQ-SG-III_4-{d + 1}-1" if d < max_range - 1 else None,
            )
        )
    return tuple(documents)


@pytest.fixture
def fulltext(documents):
    return tuple(DocumentFulltext(uuid=d.uuid, text="foo bar foo") for d in documents)


@pytest.mark.anyio
async def test_initialize_document_data(db_volume_data, documents):
    # Smoke test, if query is successful
    await initialize_document_data(documents=documents, connection=db_volume_data)


@pytest.mark.anyio
async def test_initialize_document_fulltext(db_volume_data, fulltext):
    # Smoke test, if query is successful
    await initialize_document_fulltext(documents=fulltext, connection=db_volume_data)


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


@pytest.mark.anyio
async def test_get_documents_by_fulltext(db_volume_data, documents, fulltext):
    # Naive test for the simple ft-search
    await initialize_document_data(documents=documents, connection=db_volume_data)
    await initialize_document_fulltext(documents=fulltext, connection=db_volume_data)
    search_result = await get_documents_by_ft(connection=db_volume_data, search="foo")
    assert len(search_result) == len(documents)
    assert "<mark>foo</mark>" in search_result[0].ft_match


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("idno", "expected_sort_key"),
    [
        ("SSRQ-SG-III_4-1-1", "00001.00000"),
        ("SSRQ-SG-III_4-10-1", "00010.00000"),
        ("SSRQ-SG-III_4-149-1", "00149.00000"),
    ],
)
async def test_sort_key(db_volume_data, documents, idno, expected_sort_key):
    await initialize_document_data(documents=documents, connection=db_volume_data)
    result = await get_document(connection=db_volume_data, document_id=idno)
    assert result.sort_key == expected_sort_key


@pytest.mark.anyio
async def test_get_sub_documents(db_volume_data):
    main_idno = "SSRQ-SG-III_4-2.0-1"
    main_doc = Document(
        uuid=str(uuid4()),
        idno=main_idno,
        is_main=True,
        sort_key=IDNO.model_validate_string(main_idno).normalized_sort_key,
        de_orig_date="main-de",
        en_orig_date="main-en",
        fr_orig_date="main-fr",
        it_orig_date="main-it",
        facs=None,
        printed_idno="SSRQ SG III/4 2.0",
        volume_id="SG_III_4",
        orig_place=None,
        de_title="Main title",
        fr_title=None,
        type=DocumentType.collection,
        start_year_of_creation=1200,
        end_year_of_creation=1250,
    )

    sub_1_idno = "SSRQ-SG-III_4-2.1-1"
    sub_2_idno = "SSRQ-SG-III_4-2.2-1"
    sub_docs = (
        Document(
            uuid=str(uuid4()),
            idno=sub_1_idno,
            is_main=False,
            sort_key=IDNO.model_validate_string(sub_1_idno).normalized_sort_key,
            de_orig_date="sub-de-1",
            en_orig_date="sub-en-1",
            fr_orig_date="sub-fr-1",
            it_orig_date="sub-it-1",
            facs=None,
            printed_idno="SSRQ SG III/4 2.1",
            volume_id="SG_III_4",
            orig_place=None,
            de_title="Sub title 1",
            fr_title=None,
            type=DocumentType.transcript,
            start_year_of_creation=1201,
            end_year_of_creation=1249,
        ),
        Document(
            uuid=str(uuid4()),
            idno=sub_2_idno,
            is_main=False,
            sort_key=IDNO.model_validate_string(sub_2_idno).normalized_sort_key,
            de_orig_date="sub-de-2",
            en_orig_date="sub-en-2",
            fr_orig_date="sub-fr-2",
            it_orig_date="sub-it-2",
            facs=None,
            printed_idno="SSRQ SG III/4 2.2",
            volume_id="SG_III_4",
            orig_place=None,
            de_title="Sub title 2",
            fr_title=None,
            type=DocumentType.transcript,
            start_year_of_creation=1202,
            end_year_of_creation=1248,
        ),
    )

    await initialize_document_data(
        documents=(main_doc, *sub_docs),
        connection=db_volume_data,
    )

    result = await get_sub_documents(connection=db_volume_data, document_id=main_idno)
    assert [doc.idno for doc in result] == [sub_1_idno, sub_2_idno]
