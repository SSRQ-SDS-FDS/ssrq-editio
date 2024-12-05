from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse

from ssrq_editio.adapters.db.kantons import list_kantons_abbreviations
from ssrq_editio.adapters.db.volumes import list_volumes_with_editors
from ssrq_editio.entrypoints.app.shared.dependencies import DBDependency
from ssrq_editio.entrypoints.cli.config import VOLUME_SRC
from ssrq_editio.models.kantons import KantonName
from ssrq_editio.models.volumes import Volumes
from ssrq_editio.services.volumes import stream_volume_pdf

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


@version_one.get(
    "/kantons/{kanton}}/{volume}.pdf", name="api_v1_volume_pdf", response_class=StreamingResponse
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
