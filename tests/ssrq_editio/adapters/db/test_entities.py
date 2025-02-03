from typing import Any

import aiosqlite
import pytest

from ssrq_editio.adapters.db.documents import initialize_document_data
from ssrq_editio.adapters.db.entities import (
    count_entities,
    delete_entities,
    list_entity_ids,
    search_families,
    search_keywords,
    search_lemmata,
    search_persons,
    search_places,
    store_entities,
)
from ssrq_editio.models.documents import Document
from ssrq_editio.models.entities import (
    Entities,
    EntityTypes,
    Families,
    Keywords,
    Lemmata,
    Persons,
    Places,
)


@pytest.mark.anyio
async def test_store_entities(db_setup: aiosqlite.Connection, entities: tuple[Entities, ...]):
    """Smoke test to store entities in the database."""
    try:
        await store_entities(entities, db_setup)
    except Exception as error:
        pytest.fail(str(error))


@pytest.mark.anyio
async def test_delete_entities(db_setup: aiosqlite.Connection, entities: tuple[Entities, ...]):
    """Test if entities are deleted."""
    await delete_entities(connection=db_setup)
    assert await list_entity_ids(connection=db_setup, table=EntityTypes.PLACES) == []
    assert await list_entity_ids(connection=db_setup, table=EntityTypes.PERSONS) == []
    assert await list_entity_ids(connection=db_setup, table=EntityTypes.LEMMATA) == []
    assert await list_entity_ids(connection=db_setup, table=EntityTypes.KEYWORDS) == []
    assert await list_entity_ids(connection=db_setup, table=EntityTypes.FAMILIES) == []


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("search", "expected"),
    [
        (None, len),
        ("foo bar", None),
        ("loc000127", "Zürichsee"),
        ("Zürich", []),
    ],
)
async def test_search_places(db_setup, entities, search: str | None, expected: Any):
    places = tuple([e for e in entities if isinstance(e, Places)])
    await store_entities(places, db_setup)
    result = await search_places(connection=db_setup, search=search)

    assert isinstance(result, Places)

    match expected:
        case str():
            assert len(result.entities) == 1
        case None:
            assert len(result.entities) == 0
        case _ if callable(expected):
            assert expected(places[0].entities) == expected(result.entities)
        case _:
            assert len(result.entities) > 0


@pytest.mark.anyio
async def test_search_places_with_occurrences(
    db_volume_data,
    entities,
):
    places = tuple([e for e in entities if isinstance(e, Places)])
    documents = (
        Document(
            uuid="d56f1ce8-cec9-49ed-b54b-09f397adc2d8",
            idno="SSRQ-SG-III_4-63-1",
            is_main=True,
            sort_key=63,
            de_orig_date="1473 April 26 a. S.",
            en_orig_date="1473 April 26 O.S.",
            fr_orig_date="1473 avril 26 a. s.",
            it_orig_date="1473 aprile 26 v. s.",
            facs=["OGA_Gams_Nr_5_r", "OGA_Gams_Nr_5_v"],
            printed_idno="SSRQ SG III/4 63",
            volume_id="SG_III_4",
            orig_place=["loc000211"],
            de_title="foo",
            fr_title=None,
            entities=["loc000127"],
        ),
    )
    await initialize_document_data(documents, db_volume_data)
    await store_entities(places, db_volume_data)

    result = await search_places(connection=db_volume_data, search="loc000127")

    assert isinstance(result, Places)
    assert len(result.entities) == 1
    assert result.entities[0].occurrences == [documents[0].uuid]


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("search", "expected"),
    [
        (None, len),
        ("key000129", "Wein"),
        ("Wa", []),
    ],
)
async def test_search_keywords(db_setup, entities, search: str | None, expected: Any):
    keywords = tuple([e for e in entities if isinstance(e, Keywords)])
    await store_entities(keywords, db_setup)
    result = await search_keywords(connection=db_setup, search=search)

    assert isinstance(result, Keywords)

    match expected:
        case str():
            assert len(result.entities) == 1
        case None:
            assert len(result.entities) == 0
        case _ if callable(expected):
            assert expected(keywords[0].entities) == expected(result.entities)
        case _:
            assert len(result.entities) > 0


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("search", "expected"),
    [
        (None, len),
        ("lem008330", "roter Wein"),
        ("krieg", []),
    ],
)
async def test_search_lemmata(db_setup, entities, search: str | None, expected: Any):
    lemmata = tuple([e for e in entities if isinstance(e, Lemmata)])
    await store_entities(lemmata, db_setup)
    result = await search_lemmata(connection=db_setup, search=search)

    assert isinstance(result, Lemmata)

    match expected:
        case str():
            assert len(result.entities) == 1
        case None:
            assert len(result.entities) == 0
        case _ if callable(expected):
            assert expected(lemmata[0].entities) == expected(result.entities)
        case _:
            assert len(result.entities) > 0


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("search", "expected"),
    [
        (None, len),
        ("foo bar", None),
        ("per007472", "Salis, von, Peter"),
        ("Meier", []),
    ],
)
async def test_search_persons(db_setup, entities, search: str | None, expected: Any):
    persons = tuple([e for e in entities if isinstance(e, Persons)])
    await store_entities(persons, db_setup)
    result = await search_persons(connection=db_setup, search=search)

    assert isinstance(result, Persons)

    match expected:
        case str():
            assert len(result.entities) == 1
        case None:
            assert len(result.entities) == 0
        case _ if callable(expected):
            assert expected(persons[0].entities) == expected(result.entities)
        case _:
            assert len(result.entities) > 0


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("search", "expected"),
    [
        (None, len),
        ("foo bar", None),
        ("org000195", "Vasön, von"),
        ("Meier", []),
    ],
)
async def test_search_families(db_setup, entities, search: str | None, expected: Any):
    families = tuple([e for e in entities if isinstance(e, Families)])
    await store_entities(families, db_setup)
    result = await search_families(connection=db_setup, search=search)
    assert isinstance(result, Families)

    match expected:
        case str():
            assert len(result.entities) == 1
        case None:
            assert len(result.entities) == 0
        case _ if callable(expected):
            assert expected(families[0].entities) == expected(result.entities)
        case _:
            assert len(result.entities) > 0


@pytest.mark.anyio
async def test_count_entities(
    db_setup,
    entities,
):
    places = tuple(e for e in entities if isinstance(e, Places))
    await store_entities(places, db_setup)
    result = await count_entities(connection=db_setup, table=EntityTypes.PLACES)
    assert result == len(places[0].entities)


@pytest.mark.anyio
async def test_list_entity_ids(
    db_setup,
    entities,
):
    places = tuple(e for e in entities if isinstance(e, Places))
    await store_entities(places, db_setup)
    result = await list_entity_ids(connection=db_setup, table=EntityTypes.PLACES)
    assert len(result) == len(places[0].entities)
    assert all(e_id.id in result for e_id in places[0].entities)


@pytest.mark.anyio
async def test_list_entity_ids_with_invalid_table_name(
    db_setup,
    entities,
):
    places = tuple(e for e in entities if isinstance(e, Places))
    await store_entities(places, db_setup)
    with pytest.raises(ValueError):
        await list_entity_ids(connection=db_setup, table="place")  # type: ignore
