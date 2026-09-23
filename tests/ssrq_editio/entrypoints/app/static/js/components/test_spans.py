import pytest
from playwright.sync_api import ConsoleMessage, Page

from ssrq_editio.entrypoints.app.config import ASSET_DIR

SPANS_JS = ASSET_DIR / "js/components/spans.js"
pytestmark = pytest.mark.js


def load_and_process(page: Page, html: str) -> None:
    page.set_content(html)
    before = page.locator("body").inner_html()
    source = SPANS_JS.read_text()
    page.add_script_tag(
        type="module",
        content=f"{source}\nglobalThis.processSpanMarkers = processSpanMarkers;",
    )
    page.wait_for_function("() => typeof globalThis.processSpanMarkers === 'function'")
    page.evaluate("processSpanMarkers()")
    assert page.locator("body").inner_html() == before


@pytest.mark.parametrize(
    "html",
    [
        """<div><p>foo</p><span class="addSpanStart" data-addspan-id="add1">​</span><p>bar</p><p>baz</p><span class="addSpanEnd" data-addspan-id="add1">​</span><p>qux</p></div>""",
        """<div><p>foo</p><span class="delSpanStart" data-delspan-id="del1">​</span><p>bar</p><p>baz</p><span class="delSpanEnd" data-delspan-id="del1">​</span><p>qux</p></div>""",
    ],
)
def test_process_span_markers_registers_ranges(page: Page, html: str) -> None:
    load_and_process(
        page,
        html,
    )
    result = page.evaluate(
        """() => { const h = CSS.highlights.get("tei-spans"); return { rangeCount: h.size, text: [...h][0].toString() }; }"""
    )
    assert result == {"rangeCount": 1, "text": "barbaz"}


@pytest.mark.parametrize(
    "html",
    [
        """<div><span class="addSpanStart" data-addspan-id="add1">​</span><p>foo</p><span class="addSpanEnd" data-addspan-id="add1">​</span><p>between</p><span class="addSpanStart" data-addspan-id="add2">​</span><p>bar</p><span class="addSpanEnd" data-addspan-id="add2">​</span></div>""",
        """<div><span class="delSpanStart" data-delspan-id="del1">​</span><p>foo</p><span class="delSpanEnd" data-delspan-id="del1">​</span><p>between</p><span class="delSpanStart" data-delspan-id="del2">​</span><p>bar</p><span class="delSpanEnd" data-delspan-id="del2">​</span></div>""",
    ],
)
def test_process_span_markers_registers_multiple_ranges(page: Page, html: str) -> None:
    load_and_process(
        page,
        html,
    )
    assert page.evaluate("CSS.highlights.get('tei-spans').size") == 2


@pytest.mark.parametrize(
    "html",
    [
        """<div><span class="addSpanStart" data-addspan-id="add1">​</span><p>foo</p><span class="addSpanEnd" data-addspan-id="add1">​</span></div>""",
        """<div><span class="delSpanStart" data-delspan-id="del1">​</span><p>foo</p><span class="delSpanEnd" data-delspan-id="del1">​</span></div>""",
    ],
)
def test_process_span_markers_is_idempotent(page: Page, html: str) -> None:
    load_and_process(
        page,
        html,
    )
    page.evaluate("processSpanMarkers()")
    assert page.evaluate("CSS.highlights.get('tei-spans').size") == 1


@pytest.mark.parametrize(
    ("html", "error_msg"),
    [
        (
            """<div><span class="addSpanStart" data-addspan-id="add1">​</span><p>foo</p></div>""",
            """No closing marker found for addSpan ID "add1".""",
        ),
        (
            """<div><span class="delSpanStart" data-delspan-id="del1">​</span><p>foo</p></div>""",
            """No closing marker found for delSpan ID "del1".""",
        ),
    ],
)
def test_process_span_markers_reports_missing_end_marker(
    page: Page, html: str, error_msg: str
) -> None:
    errors: list[str] = []

    def capture_error(msg: ConsoleMessage) -> None:
        if msg.type == "error":
            errors.append(msg.args[0].json_value())

    page.on("console", capture_error)
    load_and_process(
        page,
        html,
    )
    assert errors == [error_msg]


def test_process_span_markers_ignores_unsupported_browser(page: Page) -> None:
    page.set_content("<div>foo</div>")
    page.add_script_tag(content="globalThis.CSS = {}; globalThis.Highlight = undefined;")
    source = SPANS_JS.read_text()
    page.add_script_tag(
        type="module",
        content=f"{source}\nglobalThis.processSpanMarkers = processSpanMarkers;",
    )
    page.wait_for_function("() => typeof globalThis.processSpanMarkers === 'function'")
    page.evaluate("processSpanMarkers()")
    assert page.locator("body").inner_text() == "foo"
