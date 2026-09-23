from packaging.version import InvalidVersion, Version

from ssrq_editio import __version__

_PRE_RELEASE_MAP: dict[str, str] = {
    "a": "Alpha",
    "b": "Beta",
    "rc": "RC",
}


def get_display_version(version: str | None = None) -> str:
    """Convert a package version into a human-friendly format.

    Args:
        version (str | None): The raw package version. If omitted, the installed
            package version is used.

    Returns:
        The human-friendly version string.
    """
    raw = version or __version__

    try:
        parsed = Version(raw)
    except InvalidVersion:
        return raw

    release = ".".join(str(part) for part in parsed.release)
    if parsed.pre is None:
        return release

    pre_key, pre_number = parsed.pre
    return f"{release} {_PRE_RELEASE_MAP[pre_key]} {pre_number}"
