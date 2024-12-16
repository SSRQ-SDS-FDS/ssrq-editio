import pytest

from ssrq_editio.services.paginate import calc_pages, create_pages


@pytest.mark.parametrize(
    "items, current_page, per_page, expected_items, expected_pages",
    [
        (list(range(100)), 1, 10, list(range(10)), [1, 2, 3, 4, 5, -1, 10]),  # first page
        (list(range(100)), 5, 10, list(range(40, 50)), [1, -1, 4, 5, 6, -1, 10]),  # Middle page
        (list(range(100)), 10, 10, list(range(90, 100)), [1, -1, 6, 7, 8, 9, 10]),  # Last page
        (
            list(range(150)),
            10,
            15,
            list(range(135, 150)),
            [1, -1, 6, 7, 8, 9, 10],
        ),  # page with less than `per_page` elements
        (
            list(range(105)),
            7,
            15,
            list(range(90, 105)),
            [1, 2, 3, 4, 5, 6, 7],
        ),  # page with equal to `per_page` elements
        (list(range(10)), 1, 10, list(range(10)), None),  # only one page
    ],
)
def test_create_pages(
    items: list[int], current_page: int, per_page: int, expected_items, expected_pages
):
    result_items, result_pages = create_pages(items, current_page, per_page)
    assert result_items == expected_items
    assert result_pages == expected_pages


@pytest.mark.parametrize(
    ("inputs", "expected"),
    [
        ([10, 10, 1], None),
        ([11, 10, 1], [1, 2]),
        ([70, 10, 1], [1, 2, 3, 4, 5, 6, 7]),
        ([140, 10, 3], [1, 2, 3, 4, 5, -1, 14]),
        ([140, 10, 5], [1, -1, 4, 5, 6, -1, 14]),
        ([140, 10, 14], [1, -1, 10, 11, 12, 13, 14]),
        ([185, 15, 6], [1, -1, 5, 6, 7, -1, 13]),
    ],
)
def test_calc_pages(inputs, expected):
    result = calc_pages(*inputs)
    assert result == expected
