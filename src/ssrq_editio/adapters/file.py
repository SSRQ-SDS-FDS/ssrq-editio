from pathlib import Path
from anyio import open_file
import cachebox


@cachebox.cached(cachebox.Cache(maxsize=256))
async def load(dir: Path, name: str | Path) -> str:
    """Load content of a file in an async fashion.

    The loaded content is cached to avoid reading the file multiple times.

    Args:
        dir (Path): Directory where the file is located.
        name (str | Path): Name of the file to load.

    Returns:
        str: Content of the file.
    """
    async with await open_file(dir / name, "r", encoding="utf-8") as f:  # pragma: no cover
        return await f.read()
