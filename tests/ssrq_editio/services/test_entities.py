from typing import cast

import pytest
from ssrq_utils.lang.display import Lang

from ssrq_editio.models.entities import EntityTypes, Family, Organization, Person
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
async def test_resolve_places_for_families(
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


@pytest.mark.anyio
@pytest.mark.parametrize(
    "person_id,expected_location_ids,expected_location_names",
    [
        ("per019459", ["loc008965"], [{"name": "Masein", "id": "loc008965"}]),
    ],
)
async def test_resolve_places_for_persons(
    db_with_entities,
    person_id: str,
    expected_location_ids: list[str],
    expected_location_names: list[str],
):
    persons = await get_entities(
        db_with_entities,
        EntityTypes.PERSONS,
    )
    assert persons is not None
    person: Person | None = cast(Person, persons.get_by_id(person_id))
    assert person is not None
    assert person.location == expected_location_ids
    resolved_entities = await resolve_places_for_entities((person,), db_with_entities, Lang.DE)
    assert resolved_entities[0][1] == expected_location_names


@pytest.mark.anyio
@pytest.mark.parametrize(
    "organization_id,expected_location_ids,expected_location_names",
    [
        (
            "org005715",
            ["loc007992", "loc000007"],
            [{"name": "Chur", "id": "loc000007"}, {"name": "St. Luzi", "id": "loc007992"}],
        ),
    ],
)
async def test_resolve_places_for_organizations(
    db_with_entities,
    organization_id: str,
    expected_location_ids: list[str],
    expected_location_names: list[str],
):
    organizations = await get_entities(
        db_with_entities,
        EntityTypes.ORGANIZATIONS,
    )
    assert organizations is not None
    organization: Organization | None = cast(Organization, organizations.get_by_id(organization_id))
    assert organization is not None
    assert organization.location == expected_location_ids
    resolved_entities = await resolve_places_for_entities(
        (organization,), db_with_entities, Lang.DE
    )
    assert resolved_entities[0][1] == expected_location_names
