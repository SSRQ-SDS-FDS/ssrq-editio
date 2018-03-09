xquery version "3.1";

module namespace app="http://existsolutions.com/ssrq/app";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";
import module namespace common="http://www.tei-c.org/tei-simple/xquery/functions/ssrq-common" at "/db/apps/ssrq/modules/ext-common.xql";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace query="http://existsolutions.com/ssrq/search" at "ssrq-search.xql";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "lib/pages.xql";


declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $app:single-body-div-max := 7;

declare
    %templates:wrap
function app:load($node as node(), $model as map(*), $doc as xs:string, $root as xs:string?,
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
    let $hasFacs := exists($node//tei:pb[@facs]) and $data?config?odd = "ssrq.odd"
    return
        map {
            "config": $data?config,
            "data": $node,
            "body-class": if ($hasFacs) then 'col-md-6' else 'col-md-10',
            "facs-class": if ($hasFacs) then 'col-md-6' else 'hidden',
            "sidebar-class": if ($hasFacs) then 'hidden' else 'col-md-2'
        }
};

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
        $node/span
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
    let $persons :=
        root($model?data)//tei:persName/@ref |
        root($model?data)//@scribe[starts-with(., 'per')]
    where exists($persons)
    return map {
        "items":
            for $person in $persons
            group by $ref := replace($person, "^(per\d+)\w*$", "$1")
            order by $person[1]/../string() collation "?lang=de_CH"
            return
                <li data-ref="{$ref}">
                    <a target="_new"
                        href="https://www.ssrq-sds-fds.ch/persons-db-edit/?query={$person[1]}">
                        {$person[1]/../text()}
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
function app:kanton-auswahl($node as node(), $model as map(*), $filter as xs:string?, $kanton as xs:string?) {
    let $useSession := (empty($filter) or $filter = session:get-attribute("filter")) and $kanton = session:get-attribute("kanton")
    let $kanton :=
        if ($useSession) then
            session:get-attribute("kanton")
        else
            ($kanton, app:select-kanton())[1]
    for $tr in $node/tr
    let $class := if ($tr/td[2]/string() = $kanton) then 'active' else ()
    return
        <tr class="{$class}">
            { templates:process(subsequence($tr/td, 1, 2), $model) }
            <td>
            {
                let $current := $tr/td[2]
                let $docs :=
                    (
                        collection($config:data-root)/tei:TEI[starts-with(tei:teiHeader//tei:seriesStmt/tei:idno/@xml:id, $current || "_")]
                        [.//tei:text/tei:body/*]
                        | collection($config:data-root)/tei:TEI[starts-with(tei:teiHeader//tei:seriesStmt/tei:idno, "SSRQ_" || $current || "_")]
                        [.//tei:text/tei:body/*]
                    )
                    except
                        collection($config:temp-root)/tei:TEI
                return (
                    $tr/td[3]/@*,
                    if (exists($docs)) then
                        <span>
                            <a href="?kanton={$current}">{$tr/td[3]/node()} </a>
                            <span class="badge">{count($docs)}</span>
                        </span>
                    else
                        $tr/td[3]/node()
                )
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
            ($kanton, app:select-kanton())[1]
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
                doc($doc/@uri)/tei:TEI[starts-with(tei:teiHeader//tei:seriesStmt/tei:idno, "SSRQ_" || $kanton || "_")]
        else
            (
                collection($config:data-root)/tei:TEI[starts-with(tei:teiHeader//tei:seriesStmt/tei:idno/@xml:id, $kanton || "_")]
                    [.//tei:text/tei:body/*],
                collection($config:data-root)/tei:TEI[starts-with(tei:teiHeader//tei:seriesStmt/tei:idno, "SSRQ_" || $kanton || "_")]
                    [.//tei:text/tei:body/*]
            )
            except
            collection($config:temp-root)/tei:TEI
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

declare function app:select-kanton() {
    let $first := fold-left(("ZH", "BE", "LU", "UR", "SZ", "OW", "NW", "GL", "ZG", "FR", "SO", "BS", "BL", "SH", "AR", "AI", "SG",
        "GR", "AG", "TG", "TI", "VD", "VS", "NE", "GE", "JU"), (), function($zero, $kanton) {
            if ($zero) then
                $zero
            else if (exists(
                collection($config:data-root)/tei:TEI[starts-with(tei:teiHeader//tei:seriesStmt/tei:idno/@xml:id, $kanton || "_")]
                    except
                collection($config:temp-root)/tei:TEI
            )) then
                $kanton
            else
                $zero
        })
    return
        $first
};

declare %private function app:show-if-exists($node as node(), $test as node()*, $func as function(*)) {
    if ($test and normalize-space($test[1]/string()) != "") then
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
    let $idno := (
        $header/tei:fileDesc/tei:seriesStmt/tei:idno,
        $header/tei:fileDesc/tei:seriesStmt/tei:idno/@xml:id
    )[1]
    return
        app:show-if-exists($node, $idno, function() {
            common:display-sigle($idno),
            $header/tei:fileDesc//tei:msDesc/tei:history//tei:origDate/@when/string(),
            "(provisorisch)"
        })
};

declare function app:origDate($node as node(), $model as map(*)) {
    let $header := root($model?data)//tei:teiHeader
    let $origin := $header/tei:fileDesc//tei:msDesc/tei:history/tei:origin
    let $origDate := $origin/tei:origDate/@when
    let $origPlace := $origin/tei:origPlace
    return
        app:show-if-exists($node, $origDate, function() {
            string-join((
                format-date(xs:date($origDate), '[Y] [MNn] [D1]', (session:get-attribute("ssrq.lang"), "de")[1], (), ()),
                $origPlace
            ), ". ")
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
function app:additionalSource($node as node(), $model as map(*)) {
    let $idno := root($model?data)//tei:teiHeader//tei:seriesStmt/tei:idno
    return
        if (matches($idno, "_1$")) then
            let $base := replace($idno, "^(.*)_1$", '$1')
            let $additional :=
                for $header in
                    collection($config:data-root)//tei:teiHeader[matches(.//tei:seriesStmt/tei:idno, "^" || $base || "_\d+$")]
                        [not(.//tei:seriesStmt/tei:idno = $idno)]
                order by number(replace($header//tei:seriesStmt/tei:idno, "^.*_(\d+)$", "$1"))
                return
                    $header//tei:msDesc
            return
                app:show-if-exists($node, $additional, function() {
                    templates:process($node/node(), map:merge(($model, map { "data": $additional })))
                })
        else
            ()
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
function app:display-data($node as node(), $model as map(*), $mode as xs:string?) {
    for $data in $model?data
      return
    $pm-config:web-transform($data, map { "root": $data, "mode": $mode }, $config:odd)

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

declare
    %templates:wrap
function app:help($node as node(), $model as map(*)) {
    let $lang := (session:get-attribute("ssrq.lang"), "de")[1]
    let $helpDoc := doc($config:app-root || "/help.xml")
    let $helpText := (
        $helpDoc//tei:div[@xml:lang = $lang],
        $helpDoc//tei:div[@xml:lang = "de"]
    )[1]
    let $helpTitle := $helpDoc//tei:teiHeader//tei:title[@xml:lang = $lang]
    let $helpTitle := if ($helpTitle) then $helpTitle/node() else $helpDoc//tei:teiHeader//tei:title[@xml:lang = "de"]/node()
    return map {
        "body": $helpText,
        "title": $helpTitle
    }
};

declare
    %templates:wrap
function app:show-help($node as node(), $model as map(*), $field as xs:string) {
    $pm-config:web-transform($model($field), (), $config:odd)
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
