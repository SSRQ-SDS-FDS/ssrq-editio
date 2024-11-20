import pytest
from ssrq_utils.lang.display import Lang

from ssrq_editio.entrypoints.app.shared.dependencies import get_lang


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    ("x_lang", "lang", "expected_lang"),
    [
        ("en", None, Lang.EN),
        (None, "fr", Lang.FR),
        (None, None, Lang.DE),
    ],
)
async def test_get_lang(x_lang: str | None, lang: str | None, expected_lang: Lang):
    result = await get_lang(x_lang=x_lang, lang=lang)
    assert result == expected_lang
