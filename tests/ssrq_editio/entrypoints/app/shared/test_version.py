import pytest

from ssrq_editio.entrypoints.app.shared.version import get_display_version


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        ("1.2.3", "1.2.3"),
        ("1.2.3-beta.2", "1.2.3 Beta 2"),
        ("1.2.3+local", "1.2.3"),
        ("foo", "foo"),
    ],
)
def test_get_display_version(raw: str, expected: str) -> None:
    assert get_display_version(raw) == expected
