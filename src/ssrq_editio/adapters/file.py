from pathlib import Path
from typing import AsyncGenerator

import cachebox
from anyio import open_file
from anyio.to_thread import run_sync


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


async def stream(path: Path) -> AsyncGenerator[bytes, None]:
    """Stream the content of a file in an async fashion.

    Args:
        path (Path): Path to the file to stream.

    Yields:
        AsyncGenerator[bytes, None]: Bytes of the file.
    """
    async with await open_file(path, "rb") as f:
        while chunk := await f.read(1024):
            yield chunk


async def list_dir_content(dir: Path, pattern: str) -> tuple[Path, ...]:
    """List the content of a directory based on a pattern.

    Args:
        dir (Path): Directory to list the content of.
        pattern (str): Pattern to match the content against.

    Returns:
        tuple[Path, ...]: Tuple of paths matching the pattern.
    """
    return tuple(await run_sync(dir.glob, pattern))
