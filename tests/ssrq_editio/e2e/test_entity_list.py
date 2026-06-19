import re

import pytest
from playwright.sync_api import Page, expect

pytestmark = pytest.mark.e2e


def test_text_search_displays_entity_occurrences(page: Page, e2e_base_url: str) -> None:
    page.goto(f"{e2e_base_url}/index/places")

    page.locator("#entityIdOrNameSearch").fill("Konstanz")

    result = page.locator(".entity-info").filter(has_text="loc000008")
    expect(result).to_have_count(1)
    expect(page).to_have_url(
        re.compile(rf"^{re.escape(e2e_base_url)}/index/places\?.*query=Konstanz")
    )

    result.locator("summary").click()
    expect(result.get_by_role("link", name="SSRQ SG III/4 63")).to_be_visible()
