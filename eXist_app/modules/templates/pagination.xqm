xquery version "3.1";

module namespace pagination="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/pagination";

import module namespace link="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/link" at "../repository/link.xqm";

import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
(:
: A simple function, which creates a pagination
: container with the given child components.
:
: @param $position-class: The position class of the container
: @param $child-components: The child components of the container
: @return: A pagination container as div element
:)
declare function pagination:container($position-class as xs:string, $child-components as element()+) as element(div) {
    <div class="pagination-container {$position-class}">
        {$child-components}
    </div>
};

(:
: Creates a pagination-bar with the given parameters.
:
: @param $pages: The pages to be displayed
: @param $current-page: The current page to start with (1-based)
: @param $link-components: The components of the link
: @param $link-params: The parameters of the link
: @return: A pagination-bar as ul element
:)
declare function pagination:create-pages($pages as xs:integer*, $current-page as xs:integer, $link-components as xs:string*, $link-params as map(*)?) as element(ul) {
    <ul class="pagination">
        {
            for $page in $pages
            return
                if ($page = $current-page) then
                    <li class="current">
                        <button>{$page}</button>
                    </li>
                else if ($page = -1) then
                    <li class="ellipsis">
                        ...
                    </li>
                else
                    <li>
                        <a href="{link:to-app($link-components, map:merge(($link-params, map{'page': $page })))}">
                            <button>{$page}</button>
                        </a>
                    </li>
        }
    </ul>
};

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


declare function pagination:get-subsequence($items as item()+, $page as xs:integer, $per-page as xs:integer) as map(*) {
    let $total := count($items)
    return
        map {
            'subset': subsequence($items, pagination:calc-start-index($page, $per-page, $total), $per-page),
            'total': $total
        }
};

declare function pagination:calc-start-index(
    $page as xs:integer,
    $per-page as xs:integer,
    $total as xs:integer
) as xs:integer {
     if ($page = 1) then
        1
    else
        (($page - 1) * $per-page) + 1
};
