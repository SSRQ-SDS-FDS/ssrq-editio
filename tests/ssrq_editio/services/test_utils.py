import pytest

from ssrq_editio.services.utils import escape_ft_search_query


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
