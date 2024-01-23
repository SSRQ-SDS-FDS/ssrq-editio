import pytest

from tests.eXist_app.conftest import (
    assert_xquery_result,
    build_query,
    xquery_modules,
    xquery_tester,
)


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    "model, expected_lang",
    [
        ("map{}", "de"),
        (
            "map{ 'configuration': views:get-template-config(map{'parameters': map{'lang': 'fr'}})}",  # noqa
            "fr",
        ),
    ],
)
async def test_get_lang_from_model_or_config(
    execute_xquery: xquery_tester,
    model: str,
    expected_lang: str,
):
    "Test if expected lang is returned from model or config"
    xquery = build_query(
        modules=[xquery_modules["i18n-settings"], xquery_modules["views"]],
        query_body=f"""i18n-settings:get-lang-from-model-or-config({model})""",  # noqa
    )

    response = await execute_xquery(xquery)

    assert_xquery_result(response, expected_lang)
