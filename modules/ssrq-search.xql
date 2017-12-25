xquery version "3.1";

module namespace query="http://existsolutions.com/ssrq/search";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace http="http://expath.org/ns/http-client";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace browse="http://www.tei-c.org/tei-simple/templates" at "/db/apps/ssrq/modules/lib/browse.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "/db/apps/ssrq/modules/lib/util.xql";
import module namespace kwic="http://exist-db.org/xquery/kwic";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "/db/apps/ssrq/modules/navigation.xql";
import module namespace app="http://existsolutions.com/ssrq/app" at "/db/apps/ssrq/modules/ssrq.xql";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "/db/apps/ssrq/modules/pm-config.xql";
import module namespace common="http://www.tei-c.org/tei-simple/xquery/functions/ssrq-common" at "/db/apps/ssrq/modules/ext-common.xql";

declare
    %templates:default("type", "text")
function query:query($node as node()*, $model as map(*), $type as xs:string, $subtype as xs:string*, $query as xs:string?, $doc as xs:string*) as map(*) {
    let $hits :=
        if ($query) then
            switch ($type)
                case "text" return
                    query:query-texts($subtype, $query)
                default return
                    query:query-api($type, $query)
        else map {
            "hits": query:filter(collection($config:data-root)/tei:TEI//tei:body)
        }
    let $hitCount := count($hits?hits)
    let $hitsToShow := if ($hitCount > 1000) then subsequence($hits?hits, 1, 1000) else $hits?hits
    (:Store the result in the session.:)
    let $store := (
        session:set-attribute("apps.simple", $hitsToShow),
        session:set-attribute("apps.simple.hitCount", $hitCount),
        session:set-attribute("apps.simple.query", $query),
        session:set-attribute("apps.simple.type", $type),
        session:set-attribute("apps.simple.subtype", $subtype),
        session:set-attribute("apps.simple.docs", $doc)
    )
    return
        (: The hits are not returned directly, but processed by the nested templates :)
        map {
            "hits" : $hitsToShow,
            "ids": $hits?id,
            "hitCount" : $hitCount,
            "query" : $query,
            "docs": $doc
        }
};

declare function query:query-texts($subtypes as xs:string*, $query as xs:string) {
    let $hits :=
        for $subtype in $subtypes
        return
            switch ($subtype)
                case "title" return
                    collection($config:data-root)//tei:teiHeader//tei:msDesc/tei:head[ft:query(., $query)]
                case "regest" return
                    collection($config:data-root)//tei:teiHeader//tei:msDesc/tei:msContents/tei:summary[ft:query(., $query)]
                case "comment" return
                    collection($config:data-root)//tei:back[ft:query(., $query)]
                case "notes" return
                    collection($config:data-root)//tei:body//tei:note[ft:query(., $query)] |
                    collection($config:data-root)//tei:back//tei:note[ft:query(., $query)]
                case "sigle" return
                    (: Todo :)
                    ()
                (: Editionstext: body + orig in Kommentar und Fussnoten :)
                default return
                    collection($config:data-root)//tei:body[ft:query(., $query)] |
                    collection($config:data-root)//tei:back//tei:orig[ft:query(., $query)] |
                    collection($config:data-root)//tei:body//tei:note//tei:orig[ft:query(., $query)]
    return
        map {
            "hits":
                for $hit in query:filter($hits)
                order by ft:score($hit) descending
                return $hit
        }
};


declare function query:query-api($type as xs:string, $query as xs:string) as map(*) {
    let $url :=
        switch ($type)
            case "places" return
                "https://www.ssrq-sds-fds.ch/places-db-edit/views/loc-search.xq?query="
            case "lemma" return
                "https://www.ssrq-sds-fds.ch/lemma-db-edit/views/lem-search.xq?query="
            case "person" return
                "https://www.ssrq-sds-fds.ch/persons-db-api/?per_search="
            case "organisation" return
                "https://www.ssrq-sds-fds.ch/persons-db-api/?org_search="
            default return
                "https://www.ssrq-sds-fds.ch/lemma-db-edit/views/key-search.xq?query="
    let $log := console:log("Request: " || $url || encode-for-uri($query))
    let $request :=
        <http:request method="GET" href="{$url}{encode-for-uri($query)}"/>
    let $response := http:send-request($request)
    return
        if ($response[1]/@status = "200") then
            let $json := parse-json(util:binary-to-string(xs:base64Binary($response[2])))
            let $log := console:log(($response, $json))
            let $ids :=
                if ($json?results instance of map()) then
                    $json?results?id
                else
                    for-each($json?results?*, function($result) {
                        $result?id
                    })
            return
                map {
                    "id": $ids,
                    "hits":
                        for $id in $ids
                        return
                            collection($config:data-root)//tei:placeName[@ref = $id] |
                            collection($config:data-root)//tei:term[@ref = $id] |
                            collection($config:data-root)//tei:persName[@ref = $id] |
                            collection($config:data-root)//tei:orgName[@ref = $id]
                }
        else
            console:log($response[1])
};

declare function query:filter($hits as element()*) {
    fold-right(request:get-parameter-names()[starts-with(., 'filter-')], $hits, function($filter, $context) {
        let $value := request:get-parameter($filter, ())
        return
            if ($value) then
                switch ($filter)
                    case "filter-period-min" return
                        let $dateMin := xs:date($value || "-01-01")
                        return
                            $context[ancestor-or-self::tei:TEI//tei:history/tei:origin/tei:origDate/@when >= $dateMin]
                    case "filter-period-max" return
                        let $dateMax := xs:date($value || "-12-31")
                        return
                            $context[ancestor-or-self::tei:TEI//tei:history/tei:origin/tei:origDate/@when <= $dateMax]
                    case "filter-language" return
                        $context[ancestor-or-self::tei:TEI/@xml:lang = $value]
                    case "filter-condition" return
                        $context[ancestor-or-self::tei:TEI//tei:supportDesc/tei:condition = $value]
                    case "filter-material" return
                        $context[ancestor-or-self::tei:TEI//tei:support/tei:material = $value]
                    case "filter-seal" return
                        if ($value = "yes") then
                            $context[ancestor-or-self::tei:TEI//tei:sealDesc/tei:seal]
                        else
                            $context[not(ancestor-or-self::tei:TEI//tei:sealDesc/tei:seal)]
                    case "filter-author" return
                        if ($value = "yes") then
                            $context[ancestor-or-self::tei:TEI//tei:msContents/tei:msItem/tei:author/@role = 'scribe']
                        else
                            $context[not(ancestor-or-self::tei:TEI//tei:msContents/tei:msItem/tei:author/@role = 'scribe')]
                    case "filter-kanton" return
                        $context[ancestor-or-self::tei:TEI[starts-with(tei:teiHeader//tei:seriesStmt/tei:idno/@xml:id, $value || "_")]]
                    case "filter-pubdate" return
                        $context[starts-with(ancestor-or-self::tei:TEI//tei:publicationStmt/tei:date[@type='electronic']/@when, $value)]
                    default return
                        $context
            else
                $context
    })
};


declare function query:highlight($action as xs:string?, $context as element()*, $subtype as xs:string?) {
    if ($action = "search") then
        let $query := session:get-attribute("apps.simple.query")
        let $type := session:get-attribute("apps.simple.type")
        let $subtypes := session:get-attribute("apps.simple.subtype")
        let $subtype :=
            if ($subtype) then
                if (index-of($subtypes, $subtype)) then
                    $subtype
                else
                    ()
            else
                $subtypes
        return
            if ($subtype) then
                let $hits :=
                    switch ($type)
                        case "text" return
                            query:highlight-texts($context, $subtype, $query)
                        default return
                            $context
                return
                    if (exists($hits)) then
                        util:expand($hits, "add-exist-id=all")
                    else
                        $context
            else
                $context
    else
        $context
};

declare function query:highlight-texts($context as element()*, $subtypes as xs:string*, $query as xs:string) {
    console:log($subtypes),
    for $subtype in $subtypes
    return
        switch ($subtype)
            case "title" return
                $context[ft:query(., $query)]
            case "regest" case "comment" return
                $context[ft:query(., $query)]
            case "notes" return
                $context[./descendant-or-self::tei:body//tei:note[ft:query(., $query)]] |
                $context[./descendant-or-self::tei:back//tei:note[ft:query(., $query)]]
            (: Editionstext: body + orig in Kommentar und Fussnoten :)
            case "edition" return
                $context[./descendant-or-self::tei:body[ft:query(., $query)]] |
                $context[./descendant-or-self::tei:back//tei:orig[ft:query(., $query)]] |
                $context[./descendant-or-self::tei:body//tei:note//tei:orig[ft:query(., $query)]]
            default return
                ()
};

(:~
    Output the actual search result as a div, using the kwic module to summarize full text matches.
:)
declare
    %templates:wrap
    %templates:default("start", 1)
    %templates:default("per-page", 10)
function query:show-hits($node as node()*, $model as map(*), $start as xs:integer, $per-page as xs:integer, $view as xs:string?,
    $type as xs:string, $subtype as xs:string*) {
    console:log("docs: " || count($model?docs)),
    for $hit at $p in subsequence($model("hits"), $start, $per-page)
    let $parent := ($hit/self::tei:body, $hit/ancestor-or-self::tei:div[1])[1]
    let $parent := ($parent, $hit/ancestor-or-self::tei:teiHeader, $hit)[1]
    let $parent-id := config:get-identifier($parent)
    let $parent-id :=
        if ($model?docs) then replace($parent-id, "^.*?([^/]*)$", "$1") else $parent-id
    let $work := $hit/ancestor::tei:TEI
    let $config := tpu:parse-pi(root($work), $view)
    let $div := query:get-current($config, $parent)
    let $loc :=
        <tr class="reference">
            <td colspan="3">
                <span class="number">{$start + $p - 1}</span>
                <ol class="headings breadcrumb">
                    {query:header-breadcrumb($work, $parent-id)}
                    {
                        for $parentDiv in $hit/ancestor-or-self::tei:div[tei:head]
                        let $id :=
                            if ($hit/ancestor-or-self::tei:back) then
                                ()
                            else
                                util:node-id(
                                    if ($config?view = "page") then $parentDiv/preceding::tei:pb[1] else $parentDiv
                                )
                        return
                            <li>
                                <a href="{$parent-id}?action=search&amp;root={$id}&amp;view={$config?view}&amp;odd={$config?odd}">{$parentDiv/tei:head/string()}</a>
                            </li>
                    }
                </ol>
            </td>
        </tr>
    let $expanded :=
        if (exists($model?ids)) then
            (: Suche in Sachregister, $hit ist placeName :)
            query:expand($parent, $model?ids)
        else
            util:expand($hit, "add-exist-id=all")
    let $docId := config:get-identifier($div)
    let $docId :=
        if ($model?docs) then
            replace($docId, "^.*?([^/]*)$", "$1")
        else
            $docId
    return (
        $loc,
        for $match in subsequence($expanded//exist:match, 1, 5)
        let $matchId := $match/../@exist:id
        let $docLink :=
            if ($hit/ancestor-or-self::tei:back) then
                ()
            else if ($config?view = "page") then
                let $contextNode := util:node-by-id($div, $matchId)
                let $page := $contextNode/preceding::tei:pb[1]
                return
                    util:node-id($page)
            else
                util:node-id($div)
        let $action := if (exists($model?ids)) then "" else "search"
        let $config := <config width="60" table="yes"
            link="{$docId}?root={$docLink}&amp;action={$action}&amp;view={$config?view}&amp;odd={$config?odd}#{$matchId}"/>
        return
            kwic:get-summary($expanded, $match, $config)
    )
};

declare function query:header-breadcrumb($work as element(), $parent-id as xs:string) {
    let $header := $work//tei:teiHeader
    let $idno := $header/tei:fileDesc/tei:seriesStmt/tei:idno/@xml:id
    let $idno := <span>{
        common:display-sigle($idno),
        $header/tei:fileDesc//tei:msDesc/tei:history//tei:origDate/@when/string(),
        "(provisorisch)"
    }</span>
    let $head := ($header//tei:msDesc/tei:head/node(), $header//tei:titleStmt/tei:title/node())[1]
    return
        <li>
            { $idno }:
            <a href="{$parent-id}">{$pm-config:web-transform($head, map { "root": $head }, $config:odd)}</a>
        </li>
};


declare function query:expand($nodes as node()*, $ids as xs:string+) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(tei:term) | element(tei:placeName) | element(tei:persName) | element(tei:orgName) return
                element { node-name($node) } {
                    $node/@*,
                    if ($node/@ref = $ids) then
                        <exist:match>{ query:expand($node/node(), $ids) }</exist:match>
                    else
                        query:expand($node/node(), $ids)
                }
            case element() return
                element { node-name($node) } {
                    $node/@*,
                    query:expand($node/node(), $ids)
                }
            default return $node
};


declare %private function query:get-current($config as map(*), $div as element()?) {
    if (empty($div)) then
        ()
    else
        if ($div instance of element(tei:teiHeader)) then
            $div
        else
            if (
                empty($div/preceding-sibling::tei:div)  (: first div in section :)
                and count($div/preceding-sibling::*) < 5 (: less than 5 elements before div :)
                and $div/.. instance of element(tei:div) (: parent is a div :)
            ) then
                nav:get-previous-div($config, $div/..)
            else
                $div
};

declare function query:period-range($node as node(), $model as map(*)) {
    let $context :=
        if ($model?hits) then
            $model?hits ! root(.)
        else
            collection($config:data-root)
    let $dates :=
        for $when in $context//tei:teiHeader//tei:history/tei:origin/tei:origDate/@when
        return
            year-from-date(xs:date($when))
    return
        map {
            "min": min($dates),
            "max": max($dates)
        }
};

declare
    %templates:wrap
function query:condition-select($node as node(), $model as map(*), $filter-condition as xs:string?) {
    <option></option>,
    let $context :=
        if ($model?hits) then
            $model?hits ! root(.)
        else
            collection($config:data-root)
    for $condition in distinct-values($context//tei:teiHeader//tei:msDesc/tei:physDesc/tei:objectDesc/tei:supportDesc/tei:condition)
    return
        <option>
        {
            if ($condition = $filter-condition) then
                attribute selected { "selected" }
            else
                (),
            $condition
        }
        </option>
};
