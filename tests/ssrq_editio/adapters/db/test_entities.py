from typing import Any

import aiosqlite
import pytest

from ssrq_editio.adapters.db.entities import (
    count_entities,
    delete_entities,
    list_entity_ids,
    search_keywords,
    search_lemmata,
    search_persons,
    search_places,
    store_entities,
)
from ssrq_editio.models.entities import Entities, EntityTypes, Keywords, Lemmata, Persons, Places


@pytest.mark.anyio
async def test_store_entities(db_setup: aiosqlite.Connection, entities: tuple[Entities, ...]):
    """Smoke test to store entities in the database."""
    try:
        await store_entities(entities, db_setup)
    except Exception as error:
        pytest.fail(str(error))


@pytest.mark.anyio
async def test_delete_entities(db_setup: aiosqlite.Connection, entities: tuple[Entities, ...]):
    """Smoke test to store entities in the database."""
    await delete_entities(connection=db_setup)
    assert await list_entity_ids(connection=db_setup, table=EntityTypes.PLACES) == []
    assert await list_entity_ids(connection=db_setup, table=EntityTypes.PERSONS) == []
    assert await list_entity_ids(connection=db_setup, table=EntityTypes.LEMMATA) == []
    assert await list_entity_ids(connection=db_setup, table=EntityTypes.KEYWORDS) == []


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
