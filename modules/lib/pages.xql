(:
 :
 :  Copyright (C) 2015 Wolfgang Meier
 :
 :  This program is free software: you can redistribute it and/or modify
 :  it under the terms of the GNU General Public License as published by
 :  the Free Software Foundation, either version 3 of the License, or
 :  (at your option) any later version.
 :
 :  This program is distributed in the hope that it will be useful,
 :  but WITHOUT ANY WARRANTY; without even the implied warranty of
 :  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 :  GNU General Public License for more details.
 :
 :  You should have received a copy of the GNU General Public License
 :  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 :)
xquery version "3.1";

(:~
 : Template functions to handle page by page navigation and display
 : pages using TEI Simple.
 :)
module namespace pages="http://www.tei-c.org/tei-simple/pages";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace expath="http://expath.org/ns/pkg";

import module namespace templates="http://exist-db.org/xquery/templates" at "../templates.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";
import module namespace search="http://www.tei-c.org/tei-simple/search" at "search.xql";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "../navigation.xql";
import module namespace query="http://existsolutions.com/ssrq/search" at "../ssrq-search.xql";

declare variable $pages:app-root := request:get-context-path() || substring-after($config:app-root, "/db");

declare
    %templates:wrap
function pages:load($node as node(), $model as map(*), $doc as xs:string, $root as xs:string?,
    $id as xs:string?, $view as xs:string?) {
    let $doc := xmldb:decode($doc)
    let $data :=
        if ($id) then
            let $node := doc($config:data-root || "/" || $doc)/id($id)
            let $div := $node/ancestor-or-self::tei:div[1]
            let $config := tpu:parse-pi(root($node), $view)
            return
                map {
                    "config": $config,
                    "data":
                        if (empty($div)) then
                            $node/following-sibling::tei:div[1]
                        else
                            $div
                }
        else
            pages:load-xml($view, $root, $doc)
    let $node :=
        if ($data?data) then
            $data?data
        else
            <TEI xmlns="http://www.tei-c.org/ns/1.0">
                <teiHeader>
                    <fileDesc>
                        <titleStmt>
                            <title>Not found</title>
                        </titleStmt>
                    </fileDesc>
                </teiHeader>
                <text>
                    <body>
                        <div>
                            <head>Failed to load!</head>
                            <p>Could not load document {$doc}. Maybe it is not valid TEI or not in the TEI namespace?</p>
                        </div>
                    </body>
                </text>
            </TEI>//tei:div
    return
        map {
            "config": $data?config,
            "data": $node
        }
};

declare function pages:load-xml($view as xs:string?, $root as xs:string?, $doc as xs:string) {
    let $data := pages:get-document($doc)
    let $config := tpu:parse-pi(root($data), $view)
    let $log := console:log("view: " || $config?view)
    return
        map {
            "config": $config,
            "data":
                switch ($config?view)
            	    case "div" return
                        if ($root) then
                            let $node := util:node-by-id($data, $root)
                            return
                                $node/ancestor-or-self::tei:div[count(ancestor::tei:div) < $config:pagination-depth][1]
                        else
                            let $div := ($data//tei:div)[1]
                            return
                                if ($div) then
                                    $div
                                else
                                    let $group := $data/tei:TEI/tei:text/tei:group/tei:text/(tei:front|tei:body|tei:back)
                                    return
                                        if ($group) then
                                            $group[1]
                                        else
                                            $data/tei:TEI//tei:body
                    case "page" return
                        if ($root) then
                            util:node-by-id($data, $root)
                        else
                            let $div := ($data//tei:pb)[1]
                            return
                                if ($div) then
                                    $div
                                else
                                    $data/tei:TEI//tei:body
                    default return
                        if ($root) then
                            util:node-by-id($data, $root)
                        else
                            $data/tei:TEI//tei:body[1]
        }
};

declare function pages:get-document($idOrName as xs:string) {
    if ($config:address-by-id) then
        root(collection($config:data-root)/id($idOrName))
    else
        doc(xmldb:encode($config:data-root || "/" || $idOrName))
};

declare function pages:back-link($node as node(), $model as map(*)) {
    element { node-name($node) } {
        attribute href {
            $pages:app-root || "/"
        },
        $node/@*,
        $node/node()
    }
};

declare function pages:single-page-link($node as node(), $model as map(*), $doc as xs:string) {
    element { node-name($node) } {
        $node/@* except $node/@href,
        attribute href { "?view=plain&amp;odd=" || $config:odd },
        $node/node()
    }
};

declare
    %templates:default("action", "browse")
function pages:view($node as node(), $model as map(*), $action as xs:string, $sr as xs:string*, $template as xs:string?) {
    let $view := pages:determine-view($model?config?view, $model?data)
    let $data :=
        if ($action = "search" and exists(session:get-attribute("ssrq.query"))) then
            let $div :=
                if ($model?data instance of element(tei:pb)) then
                    let $nextPage := $model?data/following::tei:pb[1]
                    return
                        if ($nextPage) then
                            ($model?data/ancestor::* intersect $nextPage/ancestor::*)[last()]
                        else
                            ($model?data/ancestor::tei:div, $model?data/ancestor::tei:body)[1]
                else
                    $model?data
            let $expanded := query:highlight($action, $div, "edition", $sr)
            return
                if ($model?data instance of element(tei:pb)) then
                    $expanded//tei:pb[@exist:id = util:node-id($model?data)]
                else
                    $expanded
        else
            $model?data
    let $xml :=
        if ($view = ("div", "page", "body")) then
            pages:get-content($model?config, $data[1])
        else
            $model?data//*:body/*
    return
        pages:process-content($xml, $model?data, $model?config?odd, if ($template) then $template => substring-before('.html') else ())
};

declare function pages:process-content($xml as element()*, $root as element()*, $odd as xs:string, $view as xs:string?) {
    let $parameters := if ($view) then map {"root": $root, "view": $view} else map{"root": $root}
	let $html := $pm-config:web-transform($xml, $parameters, $odd)
    let $class := if ($html//*[@class = ('margin-note')]) then "margin-right" else ()
    let $body := pages:clean-footnotes($html)
    return
        <div class="{$config:css-content-class} {$class}">
        {
            $body,
            if ($html//li[@class = "footnote"]) then
                nav:output-footnotes($html//li[@class = "footnote"][not(ancestor::li[@class = "footnote"])])
            else
                ()
        }
        </div>
};

declare function pages:clean-footnotes($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(li) return
                if ($node/@class = "footnote") then
                    ()
                else
                    element { node-name($node) } {
                        $node/@*,
                        pages:clean-footnotes($node/node())
                    }
            case element() return
                element { node-name($node) } {
                    $node/@*,
                    pages:clean-footnotes($node/node())
                }
            default return
                $node
};

declare
    %templates:wrap
function pages:styles($node as node(), $model as map(*)) {
    attribute href {
        let $name := replace($config:odd, "^([^/\.]+).*$", "$1")
        return
            $pages:app-root || "/" || $config:output || "/" || $name || ".css"
    }
};

declare
    %templates:wrap
function pages:navigation($node as node(), $model as map(*), $view as xs:string?) {
    let $view := pages:determine-view($view, $model?data)
    let $div := $model?data
    let $work := $div/ancestor-or-self::tei:TEI
    let $map := map {
        "div" : $div,
        "work" : $work
    }
    return
        if ($view = "single") then
            $map
        else
            map:merge(($map, map {
                "previous": $config:previous-page($model?config, $div, $view),
                "next": $config:next-page($model?config, $div, $view)
            }))
};

declare function pages:get-content($config as map(*), $div as element()) {
    typeswitch ($div)
        case element(tei:teiHeader) return
            $div
        case element(tei:pb) return (
            let $nextPage := $div/following::tei:pb[1]
            let $chunk :=
                pages:milestone-chunk($div, $nextPage,
                    if ($nextPage) then
                        ($div/ancestor::* intersect $nextPage/ancestor::*)[last()]
                    else
                        ($div/ancestor::tei:div, $div/ancestor::tei:body)[1]
                )
            return
                $chunk
        )
        case element(tei:div) return
            if ($div/tei:div and count($div/ancestor::tei:div) < $config?depth - 1) then
                if ($config?fill > 0 and
                    count(($div/tei:div[1])/preceding-sibling::*//*) < $config?fill) then
                    let $child := $div/tei:div[1]
                    return
                        element { node-name($div) } {
                            $div/@* except $div/@exist:id,
                            attribute exist:id { util:node-id($div) },
                            util:expand(($child/preceding-sibling::*, $child), "add-exist-id=all")
                        }
                else
                    element { node-name($div) } {
                        $div/@* except $div/@exist:id,
                        attribute exist:id { util:node-id($div) },
                        console:log("showing preceding siblings of next div child"),
                        util:expand($div/tei:div[1]/preceding-sibling::*, "add-exist-id=all")
                    }
            else
                $div
        default return
            $div
};

declare %private function pages:milestone-chunk($ms1 as element(), $ms2 as element()?, $node as node()*) as node()*
{
    typeswitch ($node)
        case element() return
            if ($node is $ms1) then
                util:expand($node, "add-exist-id=all")
            else if ( some $n in $node/descendant::* satisfies ($n is $ms1 or $n is $ms2) ) then
                element { node-name($node) } {
                    $node/@*,
                    for $i in ( $node/node() )
                    return pages:milestone-chunk($ms1, $ms2, $i)
                }
            else if ($node >> $ms1 and (empty($ms2) or $node << $ms2)) then
                util:expand($node, "add-exist-id=all")
            else
                ()
        case attribute() return
            $node (: will never match attributes outside non-returned elements :)
        default return
            if ($node >> $ms1 and (empty($ms2) or $node << $ms2)) then $node
            else ()
};

declare function pages:title($work as element()) {
    let $main-title := $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type = 'main']/string()
    return
        if ($main-title) then $main-title else $work/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1]/string()
};

declare function pages:navigation-link($node as node(), $model as map(*), $direction as xs:string) {
        if ($model?config?view = "single") then
            ()
        else if ($model($direction)) then
            let $doc :=
                config:get-identifier($model($direction))
            return
                <a data-doc="{$doc}"
                    data-root="{util:node-id($model($direction))}"
                    data-current="{util:node-id($model('div'))}"
                    data-odd="{$config:odd}">
                {
                    $node/@* except $node/@href,
                    let $id := $doc || "?root=" || util:node-id($model($direction))
                        || "&amp;odd=" || $config:odd || "&amp;view=" || $model?config?view
                    return
                        attribute href { $id },
                    $node/node()
                }
                </a>
        else
            let $doc :=
                config:get-identifier($model?data)
            return
                <a href="#" style="visibility: hidden;"
                    data-doc="{$doc}">{$node/@class, $node/node()}</a>
};

declare function pages:app-root($node as node(), $model as map(*)) {
    element { node-name($node) } {
        $node/@*,
        attribute data-app { request:get-context-path() || substring-after($config:app-root, "/db") },
        templates:process($node/*, $model)
    }
};

declare function pages:determine-view($view as xs:string?, $node as node()) {
    typeswitch ($node)
        case element(tei:body) return
            "body"
        case element(tei:front) return
            "body"
        case element(tei:back) return
            "body"
        default return
            if ($view) then $view else $config:default-view
};

declare function pages:switch-view($node as node(), $model as map(*), $root as xs:string?, $doc as xs:string, $view as xs:string?) {
    let $view := pages:determine-view($view, $model?data)
    let $targetView := if ($view = "page") then "div" else "page"
    let $root := pages:switch-view-id($model?data, $view)
    return
        element { node-name($node) } {
            $node/@* except $node/@class,
            if (pages:has-pages($model?data) and $root) then (
                attribute href {
                    "?root=" || util:node-id($root) || "&amp;odd=" || $config:odd || "&amp;view=" || $targetView
                },
                if ($view = "page") then (
                    attribute aria-pressed { "true" },
                    attribute class { $node/@class || " active" }
                ) else
                    $node/@class
            ) else (
                $node/@class,
                attribute disabled { "disabled" }
            ),
            templates:process($node/node(), $model)
        }
};

declare function pages:has-pages($data as element()+) {
    exists((root($data)//(tei:div|tei:body))[1]//tei:pb)
};

declare function pages:switch-view-id($data as element()+, $view as xs:string) {
    let $root :=
        if ($view = "div") then
            ($data/*[1][self::tei:pb], $data/preceding::tei:pb[1])[1]
        else
            $data/ancestor::tei:div[1]
    return
        $root
};
