from pathlib import Path
import sass
from loguru import logger


def compile_sass_to_css(scss_source: Path, css_target: Path):
    logger.info(f"Compiling {scss_source} to {css_target}")
    result = sass.compile(
        filename=str(scss_source),
        output_style="compressed",
    )
    save_css(css_target, result)


def save_css(filename: Path, content: str):
    filename.parent.mkdir(parents=True, exist_ok=True)
    with open(filename, "w") as f:
        f.write(content)
