from typing import cast
import pytest
from ssrq_utils.lang.display import Lang

from ssrq_editio.entrypoints.app.shared.dependencies import db_connection
from ssrq_editio.models.entities import Entities, EntityTypes, Family
from ssrq_editio.services.entities import get_entities, resolve_places_for_entities
from ssrq_editio.services.paginate import create_pages
from ssrq_editio.services.sort import sort_entities_by_name


@pytest.mark.anyio
@pytest.mark.parametrize(
    "family_id,expected_location_ids,expected_location_names",
    [("org009447", ["loc000140"], ["Elsass"])],
)
async def test_resolve_places_for_entities(
    db_with_entities,
    family_id: str,
    expected_location_ids: list[str],
    expected_location_names: list[str],
):
    """test_values = [
        {"id": "org009447", "location": ["loc000140"], "resolved": ["Elsass"]},
        {
            "id": "org009410",
            "location": ["loc000088", "loc001060"],
            "resolved": ["Freiburg", "Luzern"],
        },
    ]"""
    families = await get_entities(
        db_with_entities,
        EntityTypes.FAMILIES,
    )
    assert families is not None
    family: Family | None = cast(Family, families.get_by_id(family_id))
    assert family is not None
    assert family.location == expected_location_ids  # type: ignore
    resolved_entities = await resolve_places_for_entities((family,), db_with_entities, Lang.DE)
    assert resolved_entities[0].location == expected_location_names  # type: ignore
