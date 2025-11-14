from math import ceil
from typing import Sequence, TypeVar

T = TypeVar("T")


def create_pages(
    items: Sequence[T], current_page: int, per_page: int = 25
) -> tuple[Sequence[T], list[int] | None]:
    """Create a pagination for a given list of items.

    Args:
        items (Sequence[T]): List of items.
        current_page (int): Current page.
        per_page (int, optional): Items per page. Defaults to 25.

    Returns:
        tuple[Sequence[T], list[int] | None]: Tuple of sliced items and pagination.
    """
    start = (current_page - 1) * per_page
    end = current_page * per_page
    return items[start:end], calc_pages(len(items), per_page, current_page)


def calc_pages(items: int, per_page: int, current_page: int) -> list[int] | None:
    """Calculate the pagination according to the
    pagination seven rule. Fills the ellipsis with -1.

    Args:
        items (int): Total number of items.
        per_page (int): Items per page.
        current_page (int): Current page.

    Returns:
        list[int]: A list of pages or None if only one page.
    """
    if (pages := ceil(items / per_page)) == 1 and current_page == 1:
        return None
    if pages <= 7:
        return list(range(1, pages + 1))
    if current_page <= 4:
        return list(range(1, 6)) + [-1, pages]
    if current_page >= pages - 3:
        return [1, -1] + list(range(pages - 4, pages + 1))
    return [1, -1] + list(range(current_page - 1, current_page + 2)) + [-1, pages]


def get_valid_page_number(current_page: int, per_page: int, total_hits: int) -> int:
    """Return a valid page number for a paginated result set.
    The page number is in the range [1, last_page]. last_page
    is derived from total_hits and per_page. If there are no hits, 1 is
    returned.

    Args:
        current_page (int): Current page number.
        per_page (int): Items per page.
        total_hits (int): number of search results.

    Returns:
        int: A valid page number between 1 and the last page.
    """
    if per_page <= 0 or total_hits <= 0:
        last_page = 1
    else:
        last_page = (total_hits - 1) // per_page + 1
    return min(max(1, current_page), last_page)
