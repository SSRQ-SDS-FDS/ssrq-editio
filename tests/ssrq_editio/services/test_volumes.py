from ssrq_editio.models.volumes import Volume
from ssrq_editio.services.volumes import create_search_pattern


def test_create_search_pattern():
    volume = Volume(
        key="foo",
        sort_key=1,
        name="foo bar",
        title="bar",
        kanton="baz",
        literature=None,
        project_page=None,
        pdf=None,
        editors=[],
        prefix="SSRQ",
    )
    result = create_search_pattern(volume)
    assert result == "foo/online/*-1.xml"
