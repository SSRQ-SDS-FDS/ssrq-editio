from asyncio import gather, get_running_loop, run
from concurrent.futures import ProcessPoolExecutor
from multiprocessing import cpu_count
from pathlib import Path
from typing import Awaitable, Callable, NamedTuple

from saxonche import PySaxonProcessor, PyXslt30Processor

from ssrq_editio.adapters.file import load
from ssrq_editio.services.xslt.config import XSLT_SRC_DIR


class XSLTParam(NamedTuple):
    name: str
    value: str | int | bool


async def apply_xslt_in_parallel(
    xml_src: tuple[str | Path, ...],
    xslt_script: str,
    params: list[XSLTParam] = [],
    xslt_src_dir: Path = XSLT_SRC_DIR,
) -> list[str | None]:
    """Applies an XSLT script to the given XML source in parallel.

    If a source is provided as a Path object, the file_loader function
    will be used to load the file. Otherwise, the source is assumed to be
    a string.

    Args:
        xml_src (tuple[str | Path, ...]): The XML source to transform.
        xslt_script (str): The XSLT script to apply.
        params (list[XSLTParam], optional): A list of parameters to pass to the XSLT
        xslt_src_dir (Path, optional): The directory where the XSLT scripts are stored.

    Returns:
        str: The transformed XML.
    """
    cpus = cpu_count()
    batch_size = (len(xml_src) + cpus - 1) // cpus
    batches = [xml_src[i * batch_size : (i + 1) * batch_size] for i in range(cpus)]
    loop = get_running_loop()

    with ProcessPoolExecutor(max_workers=cpus) as pool:
        tasks = [
            loop.run_in_executor(
                pool,
                _apply_xslt,
                *(batch, xslt_script, params, xslt_src_dir),
            )
            for batch in batches
        ]

    return [item for sublist in await gather(*tasks) for item in sublist]


async def apply_xslt(
    xml_src: tuple[str | Path, ...],
    xslt_script: str,
    params: list[XSLTParam] = [],
    xslt_src_dir: Path = XSLT_SRC_DIR,
    file_loader: Callable[[Path, str | Path], Awaitable[str]] = load,
) -> list[str | None]:
    """Applies an XSLT script to the given XML source.

    If a source is provided as a Path object, the file_loader function
    will be used to load the file. Otherwise, the source is assumed to be
    a string.

    Args:
        xml_src (tuple[str | Path, ...]): The XML source to transform.
        xslt_script (str): The XSLT script to apply.
        params (list[XSLTParam], optional): A list of parameters to pass to the XSLT
        xslt_src_dir (Path, optional): The directory where the XSLT scripts are stored.
        file_loader (Callable[[Path, str | Path], Awaitable[str]], optional): The function to load the XSLT script.

    Returns:
        str: The transformed XML.
    """
    with PySaxonProcessor(license=False) as saxon_proc:
        xslt_proc = saxon_proc.new_xslt30_processor()
        _apply_params(saxon_proc, xslt_proc, params)
        xslt_exec = xslt_proc.compile_stylesheet(stylesheet_file=str(xslt_src_dir / xslt_script))

        return [
            xslt_exec.transform_to_string(
                xdm_node=saxon_proc.parse_xml(
                    xml_text=src
                    if isinstance(src, str)
                    else await file_loader(src.parent, src.name)
                )
            )
            for src in xml_src
        ]


def _apply_xslt(
    xml_src: tuple[str | Path, ...],
    xslt_script: str,
    params: list[XSLTParam] = [],
    xslt_src_dir: Path = XSLT_SRC_DIR,
):
    """Applies an XSLT script to the given XML source (internal sync version).

    If a source is provided as a Path object, the file_loader function
    will be used to load the file. Otherwise, the source is assumed to be
    a string.

    Args:
        xml_src (tuple[str | Path, ...]): The XML source to transform.
        xslt_script (str): The XSLT script to apply.
        params (list[XSLTParam], optional): A list of parameters to pass to the XSLT
        xslt_src_dir (Path, optional): The directory where the XSLT scripts are stored.
        file_loader (Callable[[Path, str | Path], Awaitable[str]], optional): The function to load the XSLT script.

    Returns:
        str: The transformed XML.
    """
    return run(apply_xslt(xml_src, xslt_script, params, xslt_src_dir))


def _apply_params(
    saxon_proc: PySaxonProcessor, xslt_proc: PyXslt30Processor, params: list[XSLTParam]
):
    for param in params:
        match param.value:
            case str():
                xslt_proc.set_parameter(param.name, saxon_proc.make_string_value(param.value))
            case int():
                xslt_proc.set_parameter(param.name, saxon_proc.make_integer_value(param.value))
            case bool():
                xslt_proc.set_parameter(param.name, saxon_proc.make_boolean_value(param.value))
            case _:
                raise ValueError(f"Unsupported parameter type: {type(param)}")
