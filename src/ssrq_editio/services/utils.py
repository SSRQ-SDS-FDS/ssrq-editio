from pydantic_core import from_json


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
