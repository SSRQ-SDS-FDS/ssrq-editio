import pytest
from playwright.sync_api import Page, expect

pytestmark = pytest.mark.e2e


def test_transcript_document_tabs_and_metadata_toggle(page: Page, e2e_base_url: str) -> None:
    page.goto(f"{e2e_base_url}/SG/III_4/63-1")

    expect(page.locator("h1.title-1")).to_be_visible()
    expect(page.locator('[aria-label="tab-transcript"]')).to_be_visible()

    transcript_buttons = page.locator("#transcript-col nav button")
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


def test_pb_button_opens_facs_tab(page: Page, e2e_base_url: str) -> None:
    """Check whether tei:pb elements with data-facs open the facsimile tab."""
    page.goto(f"{e2e_base_url}/SG/III_4/63-1")

    expect(page.locator('[aria-label="tab-transcript"]')).to_be_visible()

    facs_panel = page.locator('[aria-label="tab-digital_copy"]')
    expect(facs_panel).to_be_hidden()

    pb_button = page.locator('button.tei-pb[data-facs="OGA_Gams_Nr_5_v"]').first
    expect(pb_button).to_be_visible()

    pb_button.click()

    expect(facs_panel).to_be_visible()
    expect(page.locator("#viewerCurrentPage")).to_have_text("2|2")


def test_pb_button_opens_facs_tab_and_metadata(page: Page, e2e_base_url: str) -> None:
    """Check whether tei:pb elements with data-facs reopen metadata and facsimile tab."""
    page.goto(f"{e2e_base_url}/SG/III_4/63-1")

    facs_panel = page.locator('[aria-label="tab-digital_copy"]')
    description_tab = page.locator('[aria-label="tab-description"]')
    expect(description_tab).to_be_visible()
    expect(facs_panel).to_be_hidden()

    page.locator("div.metadata-toggle input").click()
    expect(description_tab).to_be_hidden()

    page.locator('button.tei-pb[data-facs="OGA_Gams_Nr_5_v"]').first.click()
    expect(facs_panel).to_be_visible()
    expect(page.locator("#viewerCurrentPage")).to_have_text("2|2")


def test_pb_spacing_only_applies_when_whitespace_is_missing(page: Page, e2e_base_url: str) -> None:
    page.goto(f"{e2e_base_url}/SG/III_4/63-1")

    pb_wrappers = page.locator("span.tei-pb").filter(has=page.locator(":scope > button.tei-pb"))
    expect(pb_wrappers).to_have_count(2)

    assert pb_wrappers.nth(0).evaluate(
        "element => element.classList.contains('tei-pb-needs-space-left')"
    ) is False
    assert pb_wrappers.nth(0).evaluate(
        "element => element.classList.contains('tei-pb-needs-space-right')"
    ) is False
    assert pb_wrappers.nth(1).evaluate(
        "element => element.classList.contains('tei-pb-needs-space-left')"
    ) is True
    assert pb_wrappers.nth(1).evaluate(
        "element => element.classList.contains('tei-pb-needs-space-right')"
    ) is True
