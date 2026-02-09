import pytest
from ssrq_utils.lang.display import Lang

from ssrq_editio.models.volumes import Volume


@pytest.mark.parametrize(
    "lang, expected_url",
    [
        (Lang.DE, "https://ssrq-sds-fds.ch/blog/2022/06/10/2022-06-10-frhexen/"),
        (Lang.FR, "https://ssrq-sds-fds.ch/fr/blog/2022/06/10/2022-06-10-frhexen/"),
        (Lang.EN, "https://ssrq-sds-fds.ch/en/blog/2022/06/10/2022-06-10-frhexen/"),
        (Lang.IT, "https://ssrq-sds-fds.ch/it/blog/2022/06/10/2022-06-10-frhexen/"),
        (None, "https://ssrq-sds-fds.ch/blog/2022/06/10/2022-06-10-frhexen/"),
    ],
)
def test_get_project_page_by_lang(lang, expected_url):
    volume = Volume(
        key="foo",
        sort_key=1,
        name="foo bar",
        title="bar",
        kanton="baz",
        literature=None,
        project_page="blog/2022/06/10/2022-06-10-frhexen/",
        pdf=None,
        editors=[],
        prefix="SSRQ",
    )
    result = volume.get_project_page_by_lang(lang)
    assert result == expected_url
