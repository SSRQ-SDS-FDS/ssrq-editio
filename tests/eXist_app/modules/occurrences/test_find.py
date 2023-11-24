import pytest

from tests.eXist_app.conftest import (
    build_query,
    xquery_modules,
    xquery_tester,
    assert_xquery_result,
)


@pytest.mark.asyncio_cooperative
async def test_occurences_find_keywords(execute_xquery: xquery_tester):
    """Check if the number of found keywords is equal to the number of keywords in the article."""
    xquery = build_query(
        modules=[
            xquery_modules["finder"],
            xquery_modules["occurrences-find"],
        ],
        query_body=f"""let $d := find:article-by-idno("SSRQ-SG-III_4-1-1")
        let $keys := distinct-values($d//tei:term[starts-with(@ref, 'key')]/@ref)
        return
            count($keys) = count(occurrences-find:keywords($d))
        """,  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, True)


@pytest.mark.asyncio_cooperative
async def test_occurrences_find_lemmata(execute_xquery: xquery_tester):
    """Check if lemmata function works as expected."""
    xquery = build_query(
        modules=[
            xquery_modules["finder"],
            xquery_modules["occurrences-find"],
        ],
        query_body=f"""let $d := find:article-by-idno("SSRQ-SG-III_4-6-1")
        let $lem := distinct-values($d//tei:term[starts-with(@ref, 'lem')]/@ref)
        return
            count($lem) = count(occurrences-find:lemmata($d))
        """,  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, True)


@pytest.mark.asyncio_cooperative
async def test_occurrences_find_persons(execute_xquery: xquery_tester):
    """Check if all persons in the article are found."""
    xquery = build_query(
        modules=[
            xquery_modules["finder"],
            xquery_modules["occurrences-find"],
        ],
        query_body=f"""let $d := find:article-by-idno("SSRQ-SG-III_4-1-1")
        let $persons := distinct-values($d//tei:persName/@ref | $d//@scribe[starts-with(., 'per')])
        return
            count($persons) = count(occurrences-find:persons($d))
        """,  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, True)


@pytest.mark.asyncio_cooperative
async def test_occurrences_find_places(execute_xquery: xquery_tester):
    """Check if places function works as expected."""
    xquery = build_query(
        modules=[
            xquery_modules["finder"],
            xquery_modules["occurrences-find"],
        ],
        query_body=f"""let $d := find:article-by-idno("SSRQ-SG-III_4-1-1")
        let $places := distinct-values($d//tei:placeName[@ref]/@ref|$d//tei:origPlace[@ref]/@ref)
        return
            count($places) = count(occurrences-find:places($d))
        """,  # noqa
    )
    response = await execute_xquery(xquery)

    assert_xquery_result(response, True)


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize("function_name", ["keywords", "lemmata", "persons", "places"])
async def test_occurrences_find_with_random_idno_should_fai(
    function_name, execute_xquery: xquery_tester
):
    """Check if the eXist does not return OK, which produce an AssertionError."""
    xquery = build_query(
        modules=[
            xquery_modules["config"],
            xquery_modules["finder"],
            xquery_modules["occurrences-find"],
        ],
        query_body=f"""let $d := find:article-by-idno("foobar")
        return
            occurrences-find:{function_name}($d)
        """,  # noqa
    )
    response = await execute_xquery(xquery)
    with pytest.raises(AssertionError) as _:
        assert_xquery_result(response, True)
