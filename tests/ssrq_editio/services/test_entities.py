import pytest
from ssrq_utils.lang.display import Lang

from ssrq_editio.entrypoints.app.shared.dependencies import db_connection
from ssrq_editio.models.entities import Entities, EntityTypes
from ssrq_editio.services.entities import get_entities, resolve_places_for_entities
from ssrq_editio.services.paginate import create_pages
from ssrq_editio.services.sort import sort_entities_by_name


@pytest.mark.anyio
async def test_resolve_places_for_entities():
    test_values = [
        {"id": "org009447", "location": ["loc000140"], "resolved": ["Elsass"]},
        {
            "id": "org009410",
            "location": ["loc000088", "loc001060"],
            "resolved": ["Freiburg", "Luzern"],
        },
    ]
    async for conn in db_connection():
        result: Entities = await get_entities(
            conn,
            EntityTypes.FAMILIES,
        )
        assert result is not None
        for test_value in test_values:
            assert result.get_by_id(test_value["id"]).location == test_value["location"]
        paged_entities = create_pages(
            sort_entities_by_name(entities=result.entities, lang=Lang.DE),
            1,
            len(result.entities),
        )
        assert paged_entities is not None
        resolved_entities = await resolve_places_for_entities(paged_entities, conn, Lang.DE)
        assert resolved_entities is not None
        for test_value in test_values:
            assert result.get_by_id(test_value["id"]).location == test_value["resolved"]
        break
