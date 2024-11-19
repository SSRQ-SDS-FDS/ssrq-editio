from pathlib import Path
from ssrq_editio.adapters.file import load
import pytest


@pytest.mark.asyncio_cooperative
@pytest.mark.parametrize(
    ("filename"),
    [
        ("dummy.txt"),
        (Path("dummy.txt")),
    ],
)
async def test_load(example_path: Path, filename: str | Path):
    """Test loading the content of a dummy file."""
    assert await load(example_path, filename) == "Hello, World!\n"


@pytest.mark.asyncio_cooperative
async def test_error_loading(example_path: Path):
    """Test loading a non-existing file."""
    with pytest.raises(FileNotFoundError):
        await load(example_path, "non-existing.txt")
