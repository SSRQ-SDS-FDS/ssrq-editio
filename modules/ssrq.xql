xquery version "3.1";

module namespace app="http://existsolutions.com/ssrq/app";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $app:single-body-div-max := 7;

declare
    %templates:wrap
function app:comment($node as node(), $model as map(*)) {
    let $back := root($model?data)//tei:back
    return
        $pm-config:web-transform($back, map { "root": $back }, $config:odd)
};

declare
    %templates:wrap
function app:short-header($node as node(), $model as map(*)) {
    let $work := $model("work")/ancestor-or-self::tei:TEI
    let $view :=
        (: Switch to paginated view if we have more than $app:single-body-div-max divs :)
        if (count($work//tei:body//tei:div) > $app:single-body-div-max) then
            (: Navigate by page if there are pb :)
            if ($work//tei:body//tei:pb) then
                "page"
            else
                "div"
        (: Otherwise show the entire body :)
        else
            "body"
    let $relPath := config:get-identifier($work)
    return
        $pm-config:web-transform($work/tei:teiHeader, map {
            "header": "short",
            "doc": $relPath || "?odd=" || $model?config?odd || "&amp;view=" || $view
        }, $model?config?odd)
};
