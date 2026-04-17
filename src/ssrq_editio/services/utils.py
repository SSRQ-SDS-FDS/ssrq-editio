import re
from enum import Enum
from pathlib import Path
from typing import TypeVar

from pydantic_core import from_json, to_json
from ssrq_utils.lang.display import Lang

PROJECT_PAGE_BASE = "https://ssrq-sds-fds.ch/"
SCHEMA_PAGE_BASE = "https://schema.ssrq-sds-fds.ch/"
T = TypeVar("T")


def create_permalink(id: str, base: str = "https://p.ssrq-sds-fds.ch/") -> str:
    """Create a permalink from an id.

    ToDo: Refactor to extract the main ID from
    entitiy IDs.

    Args:
        id (str): The ID to create a permalink for.
        base (str, optional): The base URL. Defaults to "https://p.ssrq-sds-fds.ch/".

    Returns:
        str: The permalink.
    """
    return f"{base}{id}"


def escape_ft_search_query(query: str) -> str:
    """Escape special characters in a full-text search query for SQLite FTS5.

    Args:
        query (str): The full-text search query.

    Returns:
        str: The escaped query.
    """
    return re.sub(r'[#<>(){}[\]:"\']', lambda match: f'"{match.group()}"', query)


def normalize(text: str | None):
    if text is None:
        return None
    return text.strip()


def parse_as_list_or_return(value: list | str | None) -> list | None:
    """Parse a value as a list from a string or return the value.

    Args:
        value (list | None): The value to parse.

    Returns:
        list | None: The parsed value.
    """
    return value if isinstance(value, list) or value is None else from_json(value)


def build_project_url(lang: Lang | None = Lang.DE, page_path: str | None = "") -> str:
    """Build the URL for a project page in the specified language.
    For the default language (Lang.DE), no language prefix is added.

    Args:
        lang (Lang): Language enum.
        page_path (str): Relative path to the page. Leading '/' is optional.

    Returns:
        str: Fully constructed URL.
    """
    lang_path = f"{lang.value}/" if lang and lang != Lang.DE else ""
    return f"{PROJECT_PAGE_BASE}{lang_path}{page_path.lstrip('/') if page_path else ''}"


def build_schema_url(
    version: str | None = "latest", lang: Lang | None = Lang.DE, page_path: str | None = ""
) -> str:
    """Build the URL for a schema page in the specified language.
    Only French (Lang.FR) uses a language prefix. For all other languages,
    no prefix is added.

    Args:
        version (str): Schema version. Default is "latest".
        lang (Lang): Language enum.
        page_path (str): Relative path to the page. Leading '/' is optional.

    Returns:
        str: Fully constructed URL.
    """
    lang_path = f"{lang.value}/" if lang and lang == Lang.FR else ""
    version_path = f"{version}/" if version else "latest/"
    return (
        f"{SCHEMA_PAGE_BASE}{version_path}{lang_path}{page_path.lstrip('/') if page_path else ''}"
    )


def serialize_value(value: T) -> str | T:
    """Serialize a value to a string.

    If a value is a Sequence like a list it will be serialized to a JSON string.

    Args:
        value (T): The value to serialize.

    Returns:
        str | T: The serialized value.
    """
    match value:
        case Path():
            return str(value.absolute())
        case list() | dict() | tuple() | set():
            return to_json(value).decode("utf-8")
        case Enum():
            return value.value
        case _:
            return value
