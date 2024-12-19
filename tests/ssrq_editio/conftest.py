from pathlib import Path

import pytest
from ssrq_utils.i18n.translator import Translator

from ssrq_editio.entrypoints.app.config import TRANSLATION_SOURCE


@pytest.fixture(scope="session")
def example_path():
    return Path(__file__).parent / "examples"


@pytest.fixture(scope="session")
def translator():
    return Translator(TRANSLATION_SOURCE)


@pytest.fixture(scope="session")
def anyio_backend():
    return "asyncio"
