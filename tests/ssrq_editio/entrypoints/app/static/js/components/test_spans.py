import pytest
from playwright.sync_api import Page

pytestmark = pytest.mark.js


def load_and_process(page: Page, html: str) -> str:
    page.set_content(html)
    before = page.locator("body").inner_html()
    page.add_script_tag(path="src/ssrq_editio/entrypoints/app/static/js/components/spans.js")
    page.evaluate("processSpanMarkers()")
    assert page.locator("body").inner_html() == before
    return before


def test_process_span_markers_registers_ranges(page: Page) -> None:
    load_and_process(page, """<div><p>foo</p><span class="addSpanStart" data-addspan-id="add1">​</span><p>bar</p><p>baz</p><span class="addSpanEnd" data-addspan-id="add1">​</span><p>qux</p></div>""")
    result = page.evaluate("""() => { const h = CSS.highlights.get("tei-additions"); return { rangeCount: h.size, text: [...h][0].toString() }; }""")
    assert result == {"rangeCount": 1, "text": "barbaz"}


def test_process_span_markers_registers_multiple_ranges(page: Page) -> None:
    load_and_process(page, """<div><span class="addSpanStart" data-addspan-id="add1">​</span><p>foo</p><span class="addSpanEnd" data-addspan-id="add1">​</span><p>between</p><span class="addSpanStart" data-addspan-id="add2">​</span><p>bar</p><span class="addSpanEnd" data-addspan-id="add2">​</span></div>""")
    assert page.evaluate("CSS.highlights.get('tei-additions').size") == 2


def test_process_span_markers_is_idempotent(page: Page) -> None:
    load_and_process(page, """<div><span class="addSpanStart" data-addspan-id="add1">​</span><p>foo</p><span class="addSpanEnd" data-addspan-id="add1">​</span></div>""")
    page.evaluate("processSpanMarkers()")
    assert page.evaluate("CSS.highlights.get('tei-additions').size") == 1


def test_process_span_markers_reports_missing_end_marker(page: Page) -> None:
    errors: list[str] = []
    page.on("console", lambda msg: errors.append(msg.text) if msg.type == "error" else None)
    load_and_process(page, """<div><span class="addSpanStart" data-addspan-id="add1">​</span><p>foo</p></div>""")
    assert errors[0].startswith('No closing marker found for addSpan ID "add1".')


def test_process_span_markers_ignores_unsupported_browser(page: Page) -> None:
    page.set_content("<div>foo</div>")
    page.add_script_tag(content="globalThis.CSS = {}; globalThis.Highlight = undefined;")
    page.add_script_tag(path="src/ssrq_editio/entrypoints/app/static/js/components/spans.js")
    page.evaluate("processSpanMarkers()")
    assert page.locator("body").inner_text() == "foo"
