xquery version "3.1";

module namespace app="http://existsolutions.com/ssrq/app";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";
import module namespace common="http://www.tei-c.org/tei-simple/xquery/functions/ssrq-common" at "/db/apps/ssrq/modules/ext-common.xql";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace query="http://existsolutions.com/ssrq/search" at "ssrq-search.xql";


declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $app:single-body-div-max := 7;

declare function app:switch-view($node as node(), $model as map(*), $odd as xs:string?) {
    element { node-name($node) } {
        $node/@*,
        attribute href {
            if (empty($odd) or $odd = $config:odd-diplomatic) then
                "?odd=" || $config:odd-normalized
            else
                "?odd=" || $config:odd-diplomatic
        },
        <i class="material-icons">
        {
            if (empty($odd) or $odd = $config:odd-diplomatic) then
                'check_box_outline_blank'
            else
                'check_box'
        }
        </i>,
        $node/text()
    }
};


declare function app:list-places($node as node(), $model as map(*)) {
    let $places := root($model?data)//(tei:placeName[@ref]|tei:origPlace[@ref])
    where exists($places)
    return map {
        "items":
            for $place in $places
            group by $ref := replace($place/@ref, "^([^\.]+).*$", "$1")
            order by $place[1] collation "?lang=de_CH"
            return
                <li data-ref="{$ref}">
                    <a target="_new" href="https://www.ssrq-sds-fds.ch/places-db-edit/views/view-place.xq?id={$ref}">{$place[1]/string()}</a>
                </li>
    }
};

declare function app:list-keys($node as node(), $model as map(*)) {
    let $keywords := root($model?data)//tei:term[starts-with(@ref, 'key')]
    where exists($keywords)
    return map {
        "items":
            for $lemma in $keywords
            group by $ref := replace($lemma/@ref, "^([^\.]+).*$", "$1")
            order by $lemma[1] collation "?lang=de_CH"
            return
                <li data-ref="{$ref}">
                    <a href="https://www.ssrq-sds-fds.ch/lemma-db-edit/views/view-keyword.xq?id={$ref}"
                        target="_new">
                    {$lemma[1]/string()}
                    </a>
                </li>
    }
};

declare function app:list-lemmata($node as node(), $model as map(*)) {
    let $lemmata := root($model?data)//tei:term[starts-with(@ref, 'lem')]
    where exists($lemmata)
    return map {
        "items":
            for $lemma in $lemmata
            group by $ref := replace($lemma/@ref, "^([^\.]+).*$", "$1")
            order by $lemma[1] collation "?lang=de_CH"
            return
                <li data-ref="{$ref}">
                    <a target="_new"
                        href="https://www.ssrq-sds-fds.ch/lemma-db-edit/views/view-lemma.xq?id={$ref}">
                        {$lemma[1]/string()}
                    </a>
                </li>
    }
};

declare function app:list-persons($node as node(), $model as map(*)) {
    let $persons := root($model?data)//tei:persName[@ref]
    where exists($persons)
    return map {
        "items":
            for $person in $persons
            group by $ref := replace($person/@ref, "^(per\d+)\w*$", "$1")
            order by $person[1] collation "?lang=de_CH"
            return
                <li data-ref="{$ref}">
                    <a target="_new"
                        href="https://www.ssrq-sds-fds.ch/persons-db-edit/?query={$person[1]/@ref}">
                        {$person[1]/text()}
                    </a>
                </li>
    }
};

declare function app:list-organizations($node as node(), $model as map(*)) {
    let $organizations := root($model?data)//tei:orgName[@ref]
    where exists($organizations)
    return map {
        "items":
            for $organization in $organizations
            group by $ref := replace($organization/@ref, "^([^\.]+).*$", "$1")
            order by $organization[1] collation "?lang=de_DE"
            return
                <li data-ref="{$ref}">
                    <a target="_new"
                        href="https://www.ssrq-sds-fds.ch/persons-db-edit/?query={$ref}">
                        {$organization[1]/text()}
                    </a>
                </li>
    }
};

declare
    %templates:wrap
function app:show-list-items($node as node(), $model as map(*)) {
    $model?items
};

(:~
 :
 :)
declare
    %templates:wrap
function app:kanton-auswahl($node as node(), $model as map(*), $kanton as xs:string?) {
    for $tr in $node/tr
    let $class := if ($tr/td[2]/string() = $kanton) then 'active' else ()
    return
        <tr class="{$class}">
            { templates:process(subsequence($tr/td, 1, 2), $model) }
            <td>
            {
                let $current := $tr/td[2]
                let $docs := collection($config:data-root)/tei:TEI
                    [starts-with(tei:teiHeader//tei:seriesStmt/tei:idno/@xml:id, $current || "_")]
                return
                    if (exists($docs)) then
                        <span>
                            <a href="?kanton={$current}">{$tr/td[3]/text()} </a>
                            <span class="badge">{count($docs)}</span>
                        </span>
                    else
                        $tr/td[3]/text()
            }
            </td>
        </tr>
};


(:~
 : Ausgabe der Stücke nach Kanton und ggf. Filter
 :)
declare function app:list-works($node as node(), $model as map(*), $filter as xs:string?, $kanton as xs:string?, $browse as xs:string?) {
    let $useSession := (empty($filter) or $filter = session:get-attribute("filter")) and $kanton = session:get-attribute("kanton")
    let $log := console:log("Use session: " || $useSession || "; kanton=" || $kanton || "; session=" || session:get-attribute("kanton"))
    let $kanton :=
        if ($useSession) then
            session:get-attribute("kanton")
        else
            ($kanton, "ZH")[1]
    let $sessionData :=
        if ($useSession) then
            session:get-attribute("ssrq.works")
        else
            session:clear()
    let $filtered :=
        if ($sessionData) then
            $sessionData
        else if ($filter) then
            let $ordered :=
                for $item in
                    ft:search($config:data-root, $browse || ":" || $filter, ("author", "title"))/search
                let $author := $item/field[@name = "author"]
                order by $author[1], $author[2], $author[3]
                return
                    $item
            for $doc in $ordered
            return
                doc($doc/@uri)/tei:TEI[starts-with(tei:teiHeader//tei:seriesStmt/tei:idno/@xml:id, $kanton || "_")]
        else
            collection($config:data-root)/tei:TEI[starts-with(tei:teiHeader//tei:seriesStmt/tei:idno/@xml:id, $kanton || "_")]
    return (
        session:set-attribute("ssrq.works", $filtered),
        session:set-attribute("ssrq.browse", $browse),
        session:set-attribute("ssrq.filter", $filter),
        session:set-attribute("ssrq.kanton", $kanton),
        map {
            "all" : $filtered,
            "mode": "browse"
        }
    )
};


declare %private function app:show-if-exists($node as node(), $test as node()*, $func as function(*)) {
    if ($test and normalize-space($test/string()) != "") then
        element { node-name($node) } {
            $node/@*,
            $func()
        }
    else
        ()
};

declare function app:header-short($node as node(), $model as map(*), $action as xs:string?, $sr as xs:string*) {
    let $head := root($model?data)//tei:teiHeader//tei:msDesc/tei:head
    return
        app:show-if-exists($node, $head, function() {
            $pm-config:web-transform(query:highlight($action, $head, "title", $sr), map { "root": $head }, $config:odd)
        })
};


declare function app:idno($node as node(), $model as map(*)) {
    let $header := root($model?data)//tei:teiHeader
    let $idno := $header/tei:fileDesc/tei:seriesStmt/tei:idno/@xml:id
    return
        app:show-if-exists($node, $idno, function() {
            common:display-sigle($idno),
            $header/tei:fileDesc//tei:msDesc/tei:history//tei:origDate/@when/string(),
            "(provisorisch)"
        })
};

declare function app:origDate($node as node(), $model as map(*)) {
    let $header := root($model?data)//tei:teiHeader
    let $origDate := $header/tei:fileDesc//tei:msDesc/tei:history//tei:origDate/@when
    return
        app:show-if-exists($node, $origDate, function() {
            format-date(xs:date($origDate), '[Y] [MNn] [D01]')
        })
};



declare function app:comment($node as node(), $model as map(*), $action as xs:string?, $sr as xs:string*) {
    let $back := root($model?data)//tei:back
    return
        app:show-if-exists($node, $back, function() {
            templates:process($node/node(), map:merge(($model, map { "data": query:highlight($action, $back, "comment", $sr) })))
        })
};

declare function app:regest($node as node(), $model as map(*), $action as xs:string?, $sr as xs:string*) {
    let $regest := root($model?data)//tei:teiHeader//tei:msContents/tei:summary
    return
        app:show-if-exists($node, $regest, function() {
            templates:process($node/node(), map:merge(($model, map { "data": query:highlight($action, $regest, "regest", $sr) })))
        })
};

declare
    %templates:wrap
function app:source-description($node as node(), $model as map(*)) {
    let $msDesc := root($model?data)//tei:teiHeader//tei:fileDesc/tei:sourceDesc/tei:msDesc
    return
        templates:process($node/node(), map:merge(($model, map { "data": $msDesc })))
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
    return
        if ($work) then
            let $config := tpu:parse-pi(root($work), ())
            let $relPath := config:get-identifier($work)
            return
                $pm-config:web-transform($work/tei:teiHeader, map {
                    "header": "short",
                    "doc": $relPath || "?odd=" || $model?config?odd || "&amp;view=" || $config?view,
                    "root": $work
                }, $model?config?odd)
        else
            <p>Could not read {util:document-name($model?work)}</p>
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

declare function app:parse-params($node as node(), $model as map(*)) {
    element { node-name($node) } {
        for $attr in $node/@*
        return
            if (matches($attr, "\$\{[^\}]+\}")) then
                attribute { node-name($attr) } {
                    string-join(
                        let $parsed := analyze-string($attr, "\$\{([^\}]+?)(?::([^\}]+))?\}")
                        for $token in $parsed/node()
                        return
                            typeswitch($token)
                                case element(fn:non-match) return $token/string()
                                case element(fn:match) return
                                    let $paramName := $token/fn:group[1]
                                    let $default := $token/fn:group[2]
                                    let $found := [
                                        request:get-parameter($paramName, $default),
                                        $model($paramName),
                                        templates:get-configuration($model, "templates:form-control")($templates:CONFIG_PARAM_RESOLVER)($paramName)
                                    ]
                                    return
                                        array:fold-right($found, (), function($in, $value) {
                                            if (exists($in)) then $in else $value
                                        })
                                default return $token
                    )
                }
            else
                $attr,
        templates:process($node/node(), $model)
    }
};
