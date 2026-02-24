import semver

from ssrq_editio import __version__

_PRE_RELEASE_MAP: dict[str, str] = {
    "alpha": "Alpha",
    "beta": "Beta",
    "rc": "RC",
}


def get_display_version(version: str | None = None) -> str:
    """Converts a raw version string into a more human-friendly format.

    Args:
        version (str | None): The raw version string.
        If None, it defaults to the package version.

    Returns:
        str: The human-friendly version string."""
    raw = version or __version__

    try:
        parsed = semver.VersionInfo.parse(raw)
    except ValueError:
        return raw

    if not parsed.prerelease:
        return str(parsed.finalize_version())

    pre_key, *rest = parsed.prerelease.split(".", 1)
    label = _PRE_RELEASE_MAP.get(pre_key, pre_key.upper())
    if rest:
        return f"{parsed.finalize_version()} {label} {rest[0]}"
    return f"{parsed.finalize_version()} {label}"
