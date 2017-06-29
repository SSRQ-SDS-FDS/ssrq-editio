xquery version "3.1";

module namespace app="http://existsolutions.com/ssrq/app";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $app:single-body-div-max := 7;

declare %private function app:show-if-exists($node as node(), $test as element()*, $func as function(*)) {
    if ($test and normalize-space($test/string()) != "") then
        element { node-name($node) } {
            $node/@*,
            $func()
        }
    else
        ()
};

declare function app:header-short($node as node(), $model as map(*)) {
    let $head := root($model?data)//tei:teiHeader//tei:msDesc/tei:head
    return
        app:show-if-exists($node, $head, function() {
            $pm-config:web-transform($head, map { "root": $head }, $config:odd)
        })
};


declare function app:idno($node as node(), $model as map(*)) {
    let $idno := root($model?data)//tei:teiHeader//tei:msIdentifier/tei:idno
    return
        app:show-if-exists($node, $idno, function() { $idno/string() })
};

declare function app:comment($node as node(), $model as map(*)) {
    let $back := root($model?data)//tei:back
    return
        app:show-if-exists($node, $back, function() {
            templates:process($node/node(), map:merge(($model, map { "data": $back })))
        })
};

declare function app:regest($node as node(), $model as map(*)) {
    let $regest := root($model?data)//tei:teiHeader//tei:msContents/tei:summary
    return
        app:show-if-exists($node, $regest, function() {
            templates:process($node/node(), map:merge(($model, map { "data": $regest })))
        })
};

declare
    %templates:wrap
function app:display-data($node as node(), $model as map(*)) {
    $pm-config:web-transform($model?data, map { "root": $model?data }, $config:odd)
};


declare function app:show-toc($node as node(), $model as map(*), $view as xs:string?) {
    if ($view = "body") then
        ()
    else
        element { node-name($node) } {
            $node/@*,
            templates:process($node/node(), $model)
        }
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

declare
    %templates:wrap
function app:keywords($node as node(), $model as map(*)) {
    let $work := $model("work")/ancestor-or-self::tei:TEI
    let $keywords := $work/tei:teiHeader//tei:keywords/tei:term
    return
        if ($keywords) then
            map { "keywords": $keywords }
        else
            ()
};

declare
    %templates:wrap
function app:keyword($node as node(), $model as map(*)) {
    $model?keyword/text()
};
