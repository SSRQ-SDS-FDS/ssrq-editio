from pathlib import Path
from loguru import logger
import pytailwindcss
import subprocess


def compile_css(css_source: Path, css_target: Path, watch: bool = False):
    logger.info(f"Compiling {css_source} to {css_target}")
    try:
        pytailwindcss.run(
            tailwindcss_cli_args=f"--input {css_source} --output {css_target} --minify {'--watch' if watch else ''}",  # noqa
            cwd=css_source.parent,
            live_output=True,
            auto_install=True,
            version="latest",
        )
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to compile {css_source} to {css_target} with error: {e}")


def save_css(filename: Path, content: str):
    filename.parent.mkdir(parents=True, exist_ok=True)
    with open(filename, "w") as f:
        f.write(content)
