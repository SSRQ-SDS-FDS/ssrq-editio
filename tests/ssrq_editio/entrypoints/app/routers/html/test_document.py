import pytest
from httpx import AsyncClient
from httpx._status_codes import codes
from parsel import Selector

from ssrq_editio.adapters.db.documents import initialize_document_data
from ssrq_editio.adapters.db.volumes import initialize_volume_with_editors
from ssrq_editio.entrypoints.app.views.models.document import DocumentViewModel
from ssrq_editio.models.documents import Document, DocumentType
from ssrq_editio.models.volumes import Volume


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


@pytest.mark.anyio
async def test_retro_document_hides_metadata_column_and_toggles(
    app_client: AsyncClient, app_db_setup, monkeypatch: pytest.MonkeyPatch
):
    async def fake_transform_document(self: DocumentViewModel):
        return {
            "transcript": "<p>Retro marker</p>",
            "normalized_transcript": None,
            "descriptions": [],
            "summary": None,
            "comment": None,
        }

    retro_volume = Volume(
        key="ZG_1_1",
        sort_key=1,
        kanton="ZG",
        name="1/1",
        prefix="SSRQ",
        title="Retro volume",
        pdf="book/ZG_1.1.pdf",
        literature=None,
        project_page=None,
        editors=["Test Editor"],
    )
    retro_document = Document(
        uuid="9a8a9124-d4f1-46d4-9cc1-208c6e022b2e",
        idno="SSRQ-ZG-1_1-1-1",
        is_main=True,
        sort_key="00000000000000000001",
        de_orig_date="858",
        en_orig_date="858",
        fr_orig_date="858",
        it_orig_date="858",
        facs=["81"],
        printed_idno="SSRQ ZG 1/1 1",
        volume_id="ZG_1_1",
        orig_place=None,
        de_title="Retro document",
        fr_title=None,
        entities=None,
        type=DocumentType.retro,
        start_year_of_creation=858,
        end_year_of_creation=None,
    )
    await initialize_volume_with_editors(app_db_setup, retro_volume)
    await initialize_document_data((retro_document,), app_db_setup)
    monkeypatch.setattr(DocumentViewModel, "_transform_document", fake_transform_document)

    response = await app_client.get("/ZG/1_1/1-1")

    assert response.status_code == codes.OK
    doc = Selector(text=response.text)
    assert not doc.css("#metadata-col")
    assert not doc.css(".metadata-toggle")
    assert "toggle-textmarker" not in response.text
    assert "md:w-full" in doc.css("#transcript-col::attr(class)").get()
    assert not doc.css('[aria-label="tab-transcript"]')
    assert (
        doc.css("#transcript-col iframe::attr(src)").get()
        == "http://test/api/v1/kantons/ZG/1_1.pdf#page=81"
    )
