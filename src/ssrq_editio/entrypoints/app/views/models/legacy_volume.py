from enum import StrEnum

from aiosqlite import Connection
from fastapi import HTTPException, Request
from fastapi.responses import RedirectResponse
from ssrq_utils.lang.display import Lang

from ssrq_editio.models.kantons import KantonName
from ssrq_editio.models.volumes import Volume
from ssrq_editio.services.volumes import get_volume_info


class LegacyVolumeTarget(StrEnum):
    INTRO = "intro"
    LIT = "lit"


class LegacyVolumeRedirectViewModel:
    """Resolve redirects for deprecated volume-level paratext routes."""

    def __init__(
        self,
        request: Request,
        lang: Lang,
        connection: Connection,
        kanton: KantonName,
        volume: str,
        target: LegacyVolumeTarget,
    ):
        self.request = request
        self.lang = lang
        self.connection = connection
        self.kanton = kanton
        self.volume = volume
        self.target = target

    async def to_response(self) -> RedirectResponse:
        volume_info = await get_volume_info(self.connection, self.kanton, self.volume)
        return RedirectResponse(self._resolve_target(volume_info))

    def _resolve_target(self, volume_info: Volume) -> str:
        if self.target == LegacyVolumeTarget.INTRO:
            if volume_info.pdf:
                return self._build_volume_pdf_url(volume_info)
            raise HTTPException(
                status_code=404,
                detail=f"No PDF available for volume {volume_info.kanton} {volume_info.name}.",
            )

        if volume_info.literature:
            return volume_info.literature

        if volume_info.pdf:
            return self._build_volume_pdf_url(volume_info)

        raise HTTPException(
            status_code=404,
            detail=f"No literature or PDF available for volume {volume_info.kanton} {volume_info.name}.",
        )

    def _build_volume_pdf_url(self, volume_info: Volume) -> str:
        return str(
            self.request.url_for(
                "volume_pdf",
                kanton=volume_info.kanton,
                volume=volume_info.machine_name,
            ).include_query_params(lang=self.lang.value)
        )
