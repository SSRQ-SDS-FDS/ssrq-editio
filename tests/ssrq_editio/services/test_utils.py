import pytest
from ssrq_utils.lang.display import Lang

from ssrq_editio.services.utils import build_project_url, build_schema_url, escape_ft_search_query


@pytest.mark.parametrize(
    "input_query,expected_result",
    [
        ("simple query", "simple query"),
        # Single special characters
        ("<", '"<"'),
        (">", '">"'),
        ("(", '"("'),
        (")", '")"'),
        ("{", '"{"'),
        ("}", '"}"'),
        ("[", '"["'),
        ("]", '"]"'),
        (":", '":"'),
        ('"', '"""'),
        ("'", '"\'"'),
        ("query with <tags>", 'query with "<"tags">"'),
        ("query (with) parens", 'query "("with")" parens'),
        ("query [with] brackets", 'query "["with"]" brackets'),
        ('query "with" quotes', 'query """with""" quotes'),
        ("query 'with' apostrophes", 'query "\'"with"\'" apostrophes'),
        ("query {with} braces", 'query "{"with"}" braces'),
        (
            "complex (query) with [multiple] <special> {characters}",
            'complex "("query")" with "["multiple"]" "<"special">" "{"characters"}"',
        ),
        (
            'query with "quoted" and [bracketed] elements',
            'query with """quoted""" and "["bracketed"]" elements',
        ),
    ],
)
def test_escape_ft_search_query(input_query: str, expected_result: str):
    assert escape_ft_search_query(input_query) == expected_result


@pytest.mark.parametrize(
    "lang, page_path, expected_url",
    [
        (Lang.DE, "/foo", "https://ssrq-sds-fds.ch/foo"),
        (Lang.FR, "/foo", "https://ssrq-sds-fds.ch/fr/foo"),
        (None, "/foo", "https://ssrq-sds-fds.ch/foo"),
        (None, "", "https://ssrq-sds-fds.ch/"),
        (None, None, "https://ssrq-sds-fds.ch/"),
    ],
)
def test_build_project_url(
    lang: Lang,
    page_path: str,
    expected_url: str,
):
    assert build_project_url(lang, page_path) == expected_url


@pytest.mark.parametrize(
    "version, lang, page_path, expected_url",
    [
        ("latest", Lang.DE, "/foo", "https://schema.ssrq-sds-fds.ch/latest/foo"),
        ("1.8.0", Lang.DE, "/foo", "https://schema.ssrq-sds-fds.ch/1.8.0/foo"),
        (None, Lang.DE, "/foo", "https://schema.ssrq-sds-fds.ch/latest/foo"),
        (None, Lang.FR, "/foo", "https://schema.ssrq-sds-fds.ch/latest/fr/foo"),
        (None, Lang.FR, None, "https://schema.ssrq-sds-fds.ch/latest/fr/"),
        (None, None, None, "https://schema.ssrq-sds-fds.ch/latest/"),
    ],
)
def test_build_schema_url(
    version: str,
    lang: Lang,
    page_path: str,
    expected_url: str,
):
    assert build_schema_url(version, lang, page_path) == expected_url
