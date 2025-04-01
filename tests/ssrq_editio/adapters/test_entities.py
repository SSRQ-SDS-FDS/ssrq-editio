import httpx
import pytest

from ssrq_editio.adapters.entities import (
    get_families,
    get_keywords,
    get_lemmata,
    get_orgs,
    get_persons,
    get_places,
)
from ssrq_editio.models.entities import (
    Families,
    Family,
    Keywords,
    Lemmata,
    Organizations,
    Persons,
    Places,
)


@pytest.mark.anyio
async def test_get_places(httpx_client: httpx.AsyncClient):
    result = await get_places(httpx_client, "http://testserver/places.xml")
    assert result is not None
    assert isinstance(result, Places)
    assert any(place.de_name is not None for place in result.entities)
    assert all(len(place.de_place_types) > 0 for place in result.entities)


@pytest.mark.anyio
async def test_get_keywords(httpx_client: httpx.AsyncClient):
    result = await get_keywords(httpx_client, "http://testserver/keywords.xml")
    assert result is not None
    assert isinstance(result, Keywords)
    assert any(keyword.de_name is not None for keyword in result.entities)


@pytest.mark.anyio
async def test_get_lemmata(httpx_client: httpx.AsyncClient):
    result = await get_lemmata(httpx_client, "http://testserver/lemmata.xml")
    assert result is not None
    assert isinstance(result, Lemmata)
    assert any(lemma.de_name is not None for lemma in result.entities)


@pytest.mark.anyio
async def test_get_persons(httpx_client: httpx.AsyncClient):
    result = await get_persons(httpx_client, "http://testserver/persons.xml")
    assert result is not None
    assert isinstance(result, Persons)
    assert any(persons.de_name is not None for persons in result.entities)
    assert any(persons.de_surname is not None for persons in result.entities)


@pytest.mark.anyio
async def test_get_families(httpx_client: httpx.AsyncClient):
    result = await get_families(httpx_client, "http://testserver/families.xml")
    assert result is not None
    assert isinstance(result, Families)
    assert any(family.de_name is not None for family in result.entities)


@pytest.mark.anyio
async def test_location_for_specific_family(httpx_client: httpx.AsyncClient):
    result = await get_families(httpx_client, "http://testserver/families.xml")
    assert result is not None
    assert isinstance(result, Families)
    entity = result.get_by_id("org000861")
    assert entity is not None
    assert isinstance(entity, Family)
    assert entity.location == ["loc000088"]


@pytest.mark.anyio
async def test_get_orgs(httpx_client: httpx.AsyncClient):
    result = await get_orgs(httpx_client, "http://testserver/orgs.xml")
    assert result is not None
    assert isinstance(result, Organizations)
    assert any(persons.de_name is not None for persons in result.entities)
