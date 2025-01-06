import pytest
from httpx import AsyncClient
from httpx._status_codes import codes

from ssrq_editio.models.entities import EntityTypes, Keyword, Lemma, Person, Place


@pytest.mark.anyio
async def test_info(app_client: AsyncClient):
    response = await app_client.get("/api/v1/")
    assert response.status_code == codes.OK
    assert response.json() == {"message": "Version 1 of the SSRQ Editio API."}


@pytest.mark.anyio
async def test_kantons(app_client: AsyncClient):
    response = await app_client.get("/api/v1/kantons")
    assert response.status_code == codes.OK
    assert isinstance(response.json(), list)


@pytest.mark.anyio
async def test_entities(app_client: AsyncClient):
    response = await app_client.get("/api/v1/entities")
    assert response.status_code == codes.OK
    body = response.json()
    assert isinstance(body, list)
    assert all(et in EntityTypes for et in body)


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("entity_type"),
    [
        EntityTypes.PLACES,
        EntityTypes.PERSONS,
        EntityTypes.KEYWORDS,
        EntityTypes.LEMMATA,
        # ToDO Add the missing entity types
    ],
)
async def test_entity_list(app_client: AsyncClient, entity_type: EntityTypes):
    response = await app_client.get(f"/api/v1/entities/{entity_type.value}/", follow_redirects=True)
    assert response.status_code == codes.OK
    body = response.json()
    assert isinstance(body, list)
    match entity_type:
        case EntityTypes.PLACES:
            assert all(Place.model_validate(item) for item in body)
        case EntityTypes.PERSONS:
            assert all(Person.model_validate(item) for item in body)
        case EntityTypes.KEYWORDS:
            assert all(Keyword.model_validate(item) for item in body)
        case EntityTypes.LEMMATA:
            assert all(Lemma.model_validate(item) for item in body)


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("entity_type"),
    [
        ("places"),
        ("persons"),
        ("keywords"),
        ("lemmata"),
        # ToDO Add the missing entity types
    ],
)
async def test_entity_count(app_client: AsyncClient, entity_type: str):
    response = await app_client.get(f"/api/v1/entities/{entity_type}/count")
    assert response.status_code == codes.OK
    body = response.json()
    assert isinstance(body, int)
    assert body > 0


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("entity_type"),
    [
        ("places"),
        ("persons"),
        ("keywords"),
        ("lemmata"),
        # ToDO Add the missing entity types
    ],
)
async def test_entity_ids(app_client: AsyncClient, entity_type: str):
    response = await app_client.get(f"/api/v1/entities/{entity_type}/ids")
    assert response.status_code == codes.OK
    body = response.json()
    assert isinstance(body, list)
    assert len(body) > 0


@pytest.mark.anyio
@pytest.mark.parametrize(
    ("entity_type", "id", "expected"),
    [
        ("places", "loc000157", "Bern"),
        ("persons", "per018128", "Meier, Heinrich"),
        # ToDO Add the missing entity types
    ],
)
async def test_entity_std_name(app_client: AsyncClient, entity_type: str, id: str, expected: str):
    response = await app_client.get(f"/api/v1/entities/{entity_type}/{id}/name")
    assert response.status_code == codes.OK
    body = response.json()
    assert isinstance(body, str)
    assert body == expected


@pytest.mark.anyio
async def test_entity_std_name_with_unknown_id(
    app_client: AsyncClient,
):
    response = await app_client.get("/api/v1/entities/places/loc123456/name")
    assert response.status_code == codes.NOT_FOUND


@pytest.mark.anyio
async def test_entity_std_name_with_invalid_id(
    app_client: AsyncClient,
):
    response = await app_client.get("/api/v1/entities/places/lo123456/name")
    assert response.status_code == codes.BAD_REQUEST
