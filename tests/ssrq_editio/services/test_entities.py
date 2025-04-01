from typing import cast

import pytest
from ssrq_utils.lang.display import Lang

from ssrq_editio.models.entities import EntityTypes, Family
from ssrq_editio.services.entities import get_entities, resolve_places_for_entities


@pytest.mark.anyio
@pytest.mark.parametrize(
    "family_id,expected_location_ids,expected_location_names",
    [
        ("org009447", ["loc000140"], [{"name": "Elsass", "id": "loc000140"}]),
        (
            "org009410",
            ["loc000088", "loc001060"],
            [{"name": "Freiburg", "id": "loc001060"}, {"name": "Luzern", "id": "loc000088"}],
        ),
    ],
)
async def test_resolve_places_for_entities(
    db_with_entities,
    family_id: str,
    expected_location_ids: list[str],
    expected_location_names: list[str],
):
    families = await get_entities(
        db_with_entities,
        EntityTypes.FAMILIES,
    )
    assert families is not None
    family: Family | None = cast(Family, families.get_by_id(family_id))
    assert family is not None
    assert family.location == expected_location_ids  # type: ignore
    resolved_entities = await resolve_places_for_entities((family,), db_with_entities, Lang.DE)
    assert resolved_entities[0][1] == expected_location_names  # type: ignore
