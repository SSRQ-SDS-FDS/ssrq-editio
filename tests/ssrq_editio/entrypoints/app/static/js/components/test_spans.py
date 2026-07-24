import pytest
from playwright.async_api import Page

pytestmark = pytest.mark.js


@pytest.mark.parametrize(
    "html, expected",
    [
        (
            """<div>
                <p>foo</p>
                <span class="tei-addSpan addSpanStart" data-addspan-id="add1">​</span>
                <p>bar</p>
                <span class="tei-anchor addSpanEnd" data-addspan-id="add1">​</span>
                <p>baz</p>
            </div>""",
            """<div>
                <p>foo</p>
                <span class="tei-addSpan addSpanStart" data-addspan-id="add1">​</span>
                <p class="inline_content addSpan">bar</p>
                <span class="tei-anchor addSpanEnd" data-addspan-id="add1">​</span>
                <p>baz</p>
            </div>""",
        ),
        (
            """<div>
                <p>foo
                <span class="tei-addSpan addSpanStart" data-addspan-id="add1">​</span>
                bar</p>
                <p>baz</p>
                <span class="tei-anchor addSpanEnd" data-addspan-id="add1">​</span>
                <p>qux</p>
            </div>""",
            """<div>
                <p>foo
                <span class="tei-addSpan addSpanStart" data-addspan-id="add1">​</span><span class="inline_content addSpan">
                bar</span></p>
                <p class="inline_content addSpan">baz</p>
                <span class="tei-anchor addSpanEnd" data-addspan-id="add1">​</span>
                <p>qux</p>
            </div>""",
        ),
        (
            """<div>
                <p>foo</p>
                <span class="tei-addSpan addSpanStart" data-addspan-id="add1">​</span>
                <p>bar</p>
                <p>baz
                <span class="tei-anchor addSpanEnd" data-addspan-id="add1">​</span>
                qux</p>
            </div>""",
            """<div>
                <p>foo</p>
                <span class="tei-addSpan addSpanStart" data-addspan-id="add1">​</span>
                <p class="inline_content addSpan">bar</p>
                <p><span class="inline_content addSpan">baz
                </span><span class="tei-anchor addSpanEnd" data-addspan-id="add1">​</span>
                qux</p>
            </div>""",
        ),
        (
            """<div>
                <p>foo</p>
                <span class="tei-addSpan addSpanStart" data-addspan-id="add1">​</span>
                <p>bar</p>
                baz
                <p>qux</p>
                <span class="tei-anchor addSpanEnd" data-addspan-id="add1">​</span>
                <p>quux</p>
            </div>""",
            """<div>
                <p>foo</p>
                <span class="tei-addSpan addSpanStart" data-addspan-id="add1">​</span>
                <p class="inline_content addSpan">bar</p><span class="inline_content addSpan">
                baz
                </span><p class="inline_content addSpan">qux</p>
                <span class="tei-anchor addSpanEnd" data-addspan-id="add1">​</span>
                <p>quux</p>
            </div>""",
        ),
    ],
)
def test_process_span_markers(page: Page, html: str, expected: str, assert_no_errors) -> None:
    """test basic function of processSpanMarkers()."""
    page.set_content(html)
    page.add_script_tag(path="src/ssrq_editio/entrypoints/app/static/js/components/spans.js")
    page.evaluate("processSpanMarkers()")
    result = page.locator("body").inner_html()
    assert result == expected, result


def test_process_span_markers_multiple_calls(page: Page, assert_no_errors) -> None:
    """test multiple calls of processSpanMarkers()."""
    html = """<div>
                <p>foo</p>
                <span class="tei-addSpan addSpanStart" data-addspan-id="add1">​</span>
                <p>bar</p>
                <span class="tei-anchor addSpanEnd" data-addspan-id="add1">​</span>
                <p>baz</p>
            </div>"""
    expected = """<div>
                <p>foo</p>
                <span class="tei-addSpan addSpanStart" data-addspan-id="add1">​</span>
                <p class="inline_content addSpan">bar</p>
                <span class="tei-anchor addSpanEnd" data-addspan-id="add1">​</span>
                <p>baz</p>
            </div>"""

    page.set_content(html)
    page.add_script_tag(path="src/ssrq_editio/entrypoints/app/static/js/components/spans.js")
    page.evaluate("processSpanMarkers()")
    page.evaluate("processSpanMarkers()")
    result = page.locator("body").inner_html()
    assert result == expected, result


@pytest.mark.parametrize(
    "html",
    [
        """<div>
            <p>foo</p>
            <span class="tei-addSpan addSpanStart" data-addspan-id="add1">​</span>
            <p>bar</p>
        </div>""",
        """<div>
            <p>foo</p>
            <span class="tei-addSpan addSpanStart" data-addspan-id="add1">​</span>
            <p>bar</p>
            <span class="tei-anchor addSpanEnd" data-addspan-id="add2">​</span>
            <p>baz</p>
        </div>""",

    ]
)
def test_process_span_markers_missing_end_marker(page: Page, html: str) -> None:
    """test missing end marker with processSpanMarkers()."""
    error_list = []
    page.on("console", lambda msg: error_list.append(msg.text) if msg.type == "error" else None)
    page.set_content(html)
    page.add_script_tag(path="src/ssrq_editio/entrypoints/app/static/js/components/spans.js")
    page.evaluate("processSpanMarkers()")
    assert len(error_list) == 1
    assert """No closing marker found for addSpan ID "add1".""" in error_list[0]


@pytest.mark.parametrize(
    "html, expected_paths",
    [
        (
            """<div>
                <p>foo</p>
                <span class="tei-addSpan addSpanStart" data-addspan-id="add1">​</span>

                <span class="tei-anchor addSpanEnd" data-addspan-id="add1">​</span>
                <p>baz</p>
            </div>""",
            [
                "//div[count(*[@class='inline_content addSpan']) = 0]",
            ],
        ),
        (
            """<div>
                <p>foo</p>
                <span class="tei-addSpan addSpanStart" data-addspan-id="add1">​</span>
                <!-- bar -->
                <span class="tei-anchor addSpanEnd" data-addspan-id="add1">​</span>
                <p>baz</p>
            </div>""",
            [
                "//div[count(*[@class='inline_content addSpan']) = 0]",
            ],
        ),
        (
            """<div>
                <span class="tei-addSpan addSpanStart" data-addspan-id="add1">​</span>
                <p>foo</p>
                <span class="tei-anchor addSpanEnd" data-addspan-id="add1">​</span>
                <p>qux</p>
                <span class="tei-addSpan addSpanStart" data-addspan-id="add2">​</span>
                <p>bar</p>
                <span class="tei-anchor addSpanEnd" data-addspan-id="add2">​</span>
                <p>quux</p>
                <span class="tei-addSpan addSpanStart" data-addspan-id="add3">​</span>
                <p>baz</p>
                <span class="tei-anchor addSpanEnd" data-addspan-id="add3">​</span>
            </div>""",
            [
                "//div[count(*[@class='inline_content addSpan']) = 3]",
                "//div/p[1][@class='inline_content addSpan'][text() = 'foo']",
                "//div/p[2][not(@class='inline_content addSpan')][text() = 'qux']",
                "//div/p[3][@class='inline_content addSpan'][text() = 'bar']",
                "//div/p[4][not(@class='inline_content addSpan')][text() = 'quux']",
                "//div/p[5][@class='inline_content addSpan'][text() = 'baz']",
            ],
        ),
        (
            """<div>
                <span class="tei-addSpan addSpanStart" data-addspan-id="add1">​</span>
                <span>foo <span>bar</span></span>
                <span>baz</span>
                <span class="tei-anchor addSpanEnd" data-addspan-id="add1">​</span>
            </div>""",
            [
                "//div[count(*[@class='inline_content addSpan']) = 2]",
                "//div/span[@class='inline_content addSpan']/span[not(@class)]",
                "//div/span[@class='inline_content addSpan'][text() = 'baz']",
            ],
        ),
        (
            """<div>
                <span class="tei-addSpan addSpanStart" data-addspan-id="add1">​</span>
                <span>foo <span>bar</span></span>
                <span>baz</span>
                <span class="tei-anchor addSpanEnd" data-addspan-id="add1">​</span>
            </div>""",
            [
                "//div[count(*[@class='inline_content addSpan']) = 2]",
                "//div/span[@class='inline_content addSpan']/span[not(@class)]",
                "//div/span[@class='inline_content addSpan'][text() = 'baz']",
            ],
        ),
        (
            """<div>
                <span class="tei-addSpan addSpanStart" data-addspan-id="add1">​</span>
                <p>foo
                    <span>bar <span>baz</span></span>
                </p>
                <span class="tei-anchor addSpanEnd" data-addspan-id="add1">​</span>
            </div>""",
            [
                "//div[count(*[@class='inline_content addSpan']) = 1]",
                "//div/p[@class='inline_content addSpan']/span[not(@class)]/span[not(@class)][text() = 'baz']",
            ],
        ),
    ],
)
def test_process_span_markers_edge_cases(page: Page, html: str, expected_paths: list[str], assert_no_errors) -> None:
    """test edge cases of processSpanMarkers()."""
    page.set_content(html)
    page.add_script_tag(path="src/ssrq_editio/entrypoints/app/static/js/components/spans.js")
    page.evaluate("processSpanMarkers()")
    for path in expected_paths:
        assert page.locator(f"xpath={path}").count() == 1, page.locator("body").inner_html()
