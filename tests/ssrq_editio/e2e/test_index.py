import pytest
from playwright.sync_api import Page, expect

pytestmark = pytest.mark.e2e


@pytest.mark.parametrize(
    "canton, lang, expected_title",
    [
        ("ZH", "de", "I. Abteilung: Die Rechtsquellen des Kantons Zürich"),
        ("ZH", "fr", "I. Abteilung: Die Rechtsquellen des Kantons Zürich"),
        ("ZH", "it", "I. Abteilung: Die Rechtsquellen des Kantons Zürich"),
        ("FR", "de", "IX. Abteilung: Die Rechtsquellen des Kantons Freiburg"),
        ("FR", "fr", "IXe partie : Les sources du droit du canton de Fribourg"),
        ("FR", "it", "IX. Abteilung: Die Rechtsquellen des Kantons Freiburg"),
    ],
)
def test_canton_tile_by_lang_on_index_page(
    page: Page,
    e2e_base_url: str,
    canton: str,
    lang: str,
    expected_title: str,
) -> None:
    """Test if the title is displayed in the correct language on the main page, if available."""
    page.goto(f"{e2e_base_url}/?lang={lang}")
    canton_element = page.locator(".kanton-card").filter(
        has=page.get_by_role("heading", name=canton, level=4, exact=True)
    )
    expect(canton_element.locator("h3")).to_have_text(expected_title)
