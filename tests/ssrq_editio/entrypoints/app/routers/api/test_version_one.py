import pytest
from httpx import AsyncClient
from httpx._status_codes import codes

from ssrq_editio.models.entities import EntityTypes


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
        ("places"),
        ("persons"),
        ("keywords"),
        ("lemmata"),
        # ToDO Add the missing entity types
    ],
)
async def test_entity_count(app_client: AsyncClient, entity_type: str):
    response = await app_client.get(f"/api/v1/entities/{entity_type}")
    assert response.status_code == codes.OK
    body = response.json()
    assert isinstance(body, int)
    assert body > 0
