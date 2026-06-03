import pytest
from httpx import AsyncClient
from httpx._status_codes import codes
from parsel import Selector

from ssrq_editio.entrypoints.app.views.models.document import DocumentViewModel


@pytest.mark.anyio
async def test_document_page_uses_lexia_for_transcript_tabs(
    app_client: AsyncClient, monkeypatch: pytest.MonkeyPatch
):
    async def fake_transform_document(self: DocumentViewModel):
        return {
            "transcript": "<p>Transcript</p>",
            "normalized_transcript": "<p>Normalized transcript</p>",
            "descriptions": [],
            "summary": None,
            "comment": None,
        }

    monkeypatch.setattr(DocumentViewModel, "_transform_document", fake_transform_document)

    response = await app_client.get("/SG/III_4/1-1")
    assert response.status_code == codes.OK

    doc = Selector(text=response.text)
    transcript_wrappers = doc.css("#transcript-col .text-content")
    assert len(transcript_wrappers) == 2
