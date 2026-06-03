from pathlib import Path

import pytest

from ssrq_editio.entrypoints.cli.config import VOLUME_SRC
from tests.ssrq_editio.fixtures.e2e_data import missing_live_e2e_sources

pytestmark = [pytest.mark.e2e, pytest.mark.e2e_live_data]


def test_live_data_sources_are_available_for_optional_e2e_sampling() -> None:
    missing = missing_live_e2e_sources(VOLUME_SRC)
    if missing:
        pytest.skip(
            "Live E2E data submodules are not initialized: "
            + ", ".join(str(Path(path).relative_to(VOLUME_SRC)) for path in missing)
        )
