from fastapi import APIRouter, HTTPException

from ssrq_editio.adapters.db.kantons import list_kantons_abbreviations
from ssrq_editio.adapters.db.volumes import list_volumes_with_editors
from ssrq_editio.entrypoints.app.shared.dependencies import DBDependency
from ssrq_editio.models.kantons import KantonName
from ssrq_editio.models.volumes import Volumes

version_one = APIRouter(prefix="/v1", tags=["v1"])


@version_one.get("/")
def info() -> dict[str, str]:
    """Returns basic information about the API."""
    return {"message": "Version 1 of the SSRQ Editio API."}


@version_one.get("/kantons")
async def kantons(connection: DBDependency) -> list[str]:
    """Returns a list of all kantons (cantons) in abbreviated form."""
    return await list_kantons_abbreviations(connection)


@version_one.get("/kantons/{kanton}")
async def volumes(connection: DBDependency, kanton: KantonName) -> Volumes:
    """Returns information about the volumes for a specific kanton."""
    result = await list_volumes_with_editors(connection, str(kanton))
    if result is None:
        raise HTTPException(status_code=404, detail=f"No data available for »{kanton}«.")
    return Volumes(volumes=tuple(result))
