from pydantic_core import from_json


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
