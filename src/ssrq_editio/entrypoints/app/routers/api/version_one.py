from typing import Sequence, cast

from fastapi import APIRouter, HTTPException
from fastapi.responses import Response, StreamingResponse
from ssrq_utils.lang.display import Lang

from ssrq_editio.adapters.db.entities import count_entities, list_entity_ids
from ssrq_editio.adapters.db.volumes import list_volumes_with_editors
from ssrq_editio.entrypoints.app.shared.dependencies import DBDependency
from ssrq_editio.entrypoints.cli.config import VOLUME_SRC
from ssrq_editio.models.documents import DocumentIdentificationDisplay
from ssrq_editio.models.entities import (
    EntityTypes,
    Family,
    Keyword,
    Lemma,
    Organization,
    Person,
    Place,
)
from ssrq_editio.models.kantons import KantonName
from ssrq_editio.models.volumes import Volumes
from ssrq_editio.services.documents import find_and_load_xml_source
from ssrq_editio.services.entities import ENTITY_ID_PATTERN, get_entities, validate_entity_id
from ssrq_editio.services.kantons import list_kanton_abbreviations
from ssrq_editio.services.occurrences import resolve_idnos_to_documents
from ssrq_editio.services.volumes import stream_volume_pdf

version_one = APIRouter(prefix="/v1", tags=["v1"])


@version_one.get("/")
def info() -> dict[str, str]:
    """Returns basic information about the API."""
    return {"message": "Version 1 of the SSRQ Editio API."}


@version_one.get("/kantons")
async def kantons(connection: DBDependency) -> list[str]:
    """Returns a list of all kantons (cantons) in abbreviated form."""
    return await list_kanton_abbreviations(connection)


@version_one.get("/kantons/{kanton}")
async def volumes(connection: DBDependency, kanton: KantonName) -> Volumes:
    """Returns information about the volumes for a specific kanton."""
    result = await list_volumes_with_editors(connection, str(kanton))
    if result is None:
        raise HTTPException(status_code=404, detail=f"No data available for »{kanton}«.")
    return Volumes(volumes=tuple(result))


@version_one.get(
    "/kantons/{kanton}/{volume}.pdf", name="api_v1_volume_pdf", response_class=StreamingResponse
)
async def volume_pdf(
    kanton: KantonName,
    volume: str,
    connection: DBDependency,
) -> StreamingResponse:
    """Streams the PDF of a specific volume."""
    try:
        return StreamingResponse(
            await stream_volume_pdf(kanton, volume, connection, VOLUME_SRC),
            media_type="application/pdf",
        )
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))


@version_one.get("/documents/{id}/xml", name="api_v1_document_xml")
async def xml_source(id: str, connection: DBDependency):
    """Returns the XML source of a specific document."""
    try:
        return Response(
            content=await find_and_load_xml_source(connection, id), media_type="application/xml"
        )
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))


@version_one.get("/entities", name="Entities")
async def entities() -> list[EntityTypes]:
    """Returns a list of all entity types."""
    return [et for et in EntityTypes.__members__.values()]


@version_one.get("/entities/{entity}", name="entity_list")
async def entity_list(
    connection: DBDependency, entity: EntityTypes, query: str | None = None
) -> Sequence[Family | Keyword | Lemma | Organization | Person | Place]:
    """Returns a list of all entities for a specific entity type. The list is not paginated.

    Can be filtered by a query string, which is used to search for entities.
    """
    try:
        result = await get_entities(connection=connection, entity_type=entity, query=query)

        if len(result.entities) == 0:
            raise HTTPException(
                status_code=404,
                detail=f"No entities of type  »{entity.value}« found for query »{query}«.",
            )

        return cast(
            Sequence[Family | Keyword | Lemma | Organization | Person | Place], result.entities
        )
    except NotImplementedError:
        raise HTTPException(
            status_code=501, detail=f"At the moment this endpoint does not support »{entity}«."
        )


@version_one.get("/entities/{entity}/count", name="entity_count")
async def entity_count(connection: DBDependency, entity: EntityTypes) -> int:
    """Returns the number of entities in the database for a specific entity type."""
    return await count_entities(connection, entity)


@version_one.get("/entities/{entity}/ids", name="entity_ids")
async def entity_ids(connection: DBDependency, entity: EntityTypes) -> list[str]:
    """Returns a list of all entity IDs for a specific entity type."""
    return await list_entity_ids(connection, entity)


@version_one.get("/entities/{entity}/{id}", name="entity_detail")
async def entity_detail(
    connection: DBDependency, entity: EntityTypes, id: str
) -> Keyword | Lemma | Person | Place:
    """Shows the details of a specific entity."""
    if not validate_entity_id(id):
        raise HTTPException(
            status_code=400,
            detail=f"Invalid entity ID »{id}«. ID must match the pattern »{ENTITY_ID_PATTERN.pattern}«.",
        )

    try:
        # ToDO: Replace the try / except approach with a more elegant solution.
        return (await get_entities(connection=connection, entity_type=entity, query=id)).entities[0]  # type: ignore # ToDO: Fix typing here...
    except IndexError:
        raise HTTPException(status_code=404, detail=f"No entity found with ID »{id}«.")
    except NotImplementedError:
        raise HTTPException(
            status_code=501,
            detail=f"At the moment this endpoint does not support »{entity}« or no entity found with {id}.",
        )


@version_one.get("/entities/{entity}/{id}/name", name="entity_name")
async def entity_std_name(
    connection: DBDependency,
    entity: EntityTypes,
    id: str,
    lang: Lang = Lang.DE,  # ToDo: Also allow other languages like rm, pl, etc.
) -> str:
    """Show the standard-name of an entity for a given language. If there is no name for this
    language the standard-names are retrieved in the following order: de, fr, it, lt, rm.."""
    if not validate_entity_id(id):
        raise HTTPException(
            status_code=400,
            detail=f"Invalid entity ID »{id}«. ID must match the pattern »{ENTITY_ID_PATTERN.pattern}«.",
        )

    try:
        return (
            (await get_entities(connection=connection, entity_type=entity, query=id))
            .entities[0]
            .get_name_by_lang(lang)
        )  # type: ignore # ToDO: Fix typing here...
    except IndexError:
        raise HTTPException(status_code=404, detail=f"No entity found with ID »{id}«.")
    except NotImplementedError:
        raise HTTPException(
            status_code=501,
            detail=f"At the moment this endpoint does not support »{entity}«.",
        )


@version_one.get("/entities/{entity}/{id}/occurrences", name="entity_occurrences")
async def entity_occurrences(
    connection: DBDependency, entity: EntityTypes, id: str
) -> list[DocumentIdentificationDisplay] | None:
    """Return all occurrences (document references) associated with a specific entity.
    The response is a list of `DocumentIdentificationDisplay` objects including volume information."""
    if not validate_entity_id(id):
        raise HTTPException(
            status_code=400,
            detail=f"Invalid entity ID »{id}«. ID must match the pattern »{ENTITY_ID_PATTERN.pattern}«.",
        )

    try:
        # ToDO: Replace the try / except approach with a more elegant solution.
        entity_occurrences = (
            (await get_entities(connection=connection, entity_type=entity, query=id))
            .entities[0]
            .occurrences
        )
        return (
            await resolve_idnos_to_documents(connection=connection, occurrences=entity_occurrences)
            if entity_occurrences
            else None
        )
    except IndexError:
        raise HTTPException(status_code=404, detail=f"No entity found with ID »{id}«.")
    except NotImplementedError:
        raise HTTPException(
            status_code=501,
            detail=f"At the moment this endpoint does not support »{entity}« or no entity found with {id}.",
        )
