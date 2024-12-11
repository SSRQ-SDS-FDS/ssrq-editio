from typing import Any

import aiosqlite
import pytest

from ssrq_editio.adapters.db.entities import search_places, store_entities
from ssrq_editio.models.entities import Entities, Places


@pytest.mark.asyncio_cooperative
async def test_store_entities(db_setup: aiosqlite.Connection, entities: tuple[Entities, ...]):
    """Smoke test to store entities in the database."""
    try:
        await store_entities(entities, db_setup)
    except Exception as error:
        pytest.fail(str(error))


@pytest.mark.asyncio_cooperative
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
