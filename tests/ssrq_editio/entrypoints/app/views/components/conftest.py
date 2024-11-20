import jinjax
import pytest

from ssrq_editio.entrypoints.app.config import COMPONENT_DIR


@pytest.fixture()
def catalog() -> jinjax.Catalog:
    catalog = jinjax.Catalog(auto_reload=False)
    catalog.add_folder(COMPONENT_DIR)
    return catalog
