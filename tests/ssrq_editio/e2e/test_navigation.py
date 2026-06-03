import pytest
from playwright.sync_api import Page, expect

pytestmark = pytest.mark.e2e


def test_can_navigate_from_index_to_volume_documents(page: Page, e2e_base_url: str) -> None:
    page.goto(f"{e2e_base_url}/")

    sg_link = page.locator('#cantonlist a[href*="/SG"]')
    expect(sg_link).to_have_count(1)
    sg_link.click()

    expect(page).to_have_url(f"{e2e_base_url}/SG?lang=de")
    sg_volume = page.locator("article.volume").filter(has_text="SSRQ SG III/4")
    expect(sg_volume).to_have_count(1)

    sg_volume.locator('a[href*="/SG/III_4"]').click()

    expect(page).to_have_url(f"{e2e_base_url}/SG/III_4?lang=de")
    expect(page.locator(".document-info")).to_have_count(2)
