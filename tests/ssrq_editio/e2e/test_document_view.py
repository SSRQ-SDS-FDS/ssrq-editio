import pytest
from playwright.sync_api import Page, expect

pytestmark = pytest.mark.e2e


def test_transcript_document_tabs_and_metadata_toggle(page: Page, e2e_base_url: str) -> None:
    page.goto(f"{e2e_base_url}/SG/III_4/63-1")

    expect(page.locator("h1.title-1")).to_be_visible()
    expect(page.locator('[aria-label="tab-transcript"]')).to_be_visible()

    transcript_buttons = page.locator("#transcript-col button")
    expect(transcript_buttons).to_have_count(3)
    transcript_buttons.nth(1).click()
    expect(page.locator('[aria-label="tab-normalized"]')).to_be_visible()

    metadata_column = page.locator("#metadata-col")
    expect(metadata_column).to_be_visible()
    page.locator("label").filter(has_text="Metadaten").locator('input[type="checkbox"]').click()
    expect(metadata_column).to_be_hidden()


def test_collection_document_shows_subdocument_information(page: Page, e2e_base_url: str) -> None:
    page.goto(f"{e2e_base_url}/FR/I_2_8/83.0-1")

    expect(page.locator("h1.title-1")).to_be_visible()
    transcript_panel = page.locator('[aria-label="tab-transcript"]')
    expect(transcript_panel).to_be_visible()
    expect(transcript_panel).to_contain_text("Erstes Unterstuck zum Freiburger Mantelstuck")
    expect(transcript_panel).to_contain_text("Zweites Unterstuck zum Freiburger Mantelstuck")
