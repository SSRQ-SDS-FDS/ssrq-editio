from pathlib import Path

import pytest


@pytest.fixture
def example_path():
    return Path(__file__).parent / "examples"
