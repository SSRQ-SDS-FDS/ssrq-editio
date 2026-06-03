import re

import pytest
from playwright.sync_api import Page, expect

pytestmark = pytest.mark.e2e


def test_document_list_filters_by_query(page: Page, e2e_base_url: str) -> None:
    page.goto(f"{e2e_base_url}/SG/III_4")
    expect(page.locator(".document-info")).to_have_count(2)

    page.locator("#documentIdOrTitleSearch").fill("Zolltarif")

    result = page.locator(".document-info").filter(has_text="SSRQ SG III/4 245")
    expect(result).to_have_count(1)
    expect(page.locator(".document-info")).to_have_count(1)
    expect(page).to_have_url(re.compile(rf"^{re.escape(e2e_base_url)}/SG/III_4\?.*query=Zolltarif"))


def test_document_list_can_filter_collections(page: Page, e2e_base_url: str) -> None:
    page.goto(f"{e2e_base_url}/FR/I_2_8")

    page.locator("#docTypeSelect").select_option("collection")

    collection = page.locator(".document-info").filter(has_text="SSRQ FR I/2/8 83.0")
    expect(collection).to_have_count(1)
    expect(page.locator(".document-info")).to_have_count(1)
    expect(page).to_have_url(
        re.compile(rf"^{re.escape(e2e_base_url)}/FR/I_2_8\?.*doc_type=collection")
    )
