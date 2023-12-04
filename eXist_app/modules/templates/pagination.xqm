xquery version "3.1";

module namespace pagination="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/pagination";

(:
: A simple and straightforward function,
: which calculates the pages based on the
: pagination-seven pattern.
: @param $items: The total number of items
: @param $per-page: The number of items per page
: @param $current-page: The number of the current page
: @return: A sequence of pages – where -1 is a placeholder for "..."
:)
declare function pagination:calc-pages(
    $items as xs:integer,
    $per-page as xs:integer,
    $current-page as xs:integer
) as xs:integer* {
    let $pages := xs:integer(ceiling($items div $per-page))
    return
        if ($pages = 1 and $current-page = 1) then ()
        else if ($pages <= 7) then (1 to $pages)
        else if ($current-page <= 4) then (1 to 5, -1, $pages)
        else if ($current-page >= $pages - 3) then (1, -1, ($pages - 4) to $pages)
        else (1, -1, ($current-page - 1) to ($current-page + 1), -1, $pages)
};
