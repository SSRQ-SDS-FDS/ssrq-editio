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
function query:query($node as node()*, $model as map(*), $type as xs:string, $query as xs:string?, $doc as xs:string*) as map(*) {
        (:If there is no query string, fill up the map with existing values:)
        if (empty($query))
        then
            map {
                "hits" : session:get-attribute("apps.simple"),
                "hitCount" : session:get-attribute("apps.simple.hitCount"),
                "query" : session:get-attribute("apps.simple.query"),
                "docs" : session:get-attribute("apps.simple.docs")
            }
        else
            (:Otherwise, perform the query.:)
            (: Here the actual query commences. This is split into two parts, the first for a Lucene query and the second for an ngram query. :)
            (:The query passed to a Luecene query in ft:query is an XML element <query> containing one or two <bool>. The <bool> contain the original query and the transliterated query, as indicated by the user in $query-scripts.:)
            let $hits :=
                switch ($type)
                    case "text" return
                        map {
                            "hits":
                                for $hit in collection($config:data-root)//tei:body[ft:query(., $query)]
                                order by ft:score($hit) descending
                                return $hit
                        }
                    default return
                        query:query-api($type, $query)
            let $hitCount := count($hits?hits)
            let $hitsToShow := if ($hitCount > 1000) then subsequence($hits?hits, 1, 1000) else $hits?hits
            (:Store the result in the session.:)
            let $store := (
                session:set-attribute("apps.simple", $hitsToShow),
                session:set-attribute("apps.simple.hitCount", $hitCount),
                session:set-attribute("apps.simple.query", $query),
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

declare function query:query-api($type as xs:string, $query as xs:string) as map(*) {
    let $url :=
        switch ($type)
            case "places" return
                "https://www.ssrq-sds-fds.ch/places-db-edit/views/loc-search.xq?query="
            case "lemma" return
                "https://www.ssrq-sds-fds.ch/lemma-db-edit/views/lem-search.xq?query="
            default return
                "https://www.ssrq-sds-fds.ch/lemma-db-edit/views/key-search.xq?query="
    let $request :=
        <http:request method="GET" href="{$url}{$query}"/>
    let $response := http:send-request($request)
    return
        if ($response[1]/@status = "200") then
            let $json := parse-json(util:binary-to-string(xs:base64Binary($response[2])))
            let $log := console:log($json)
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
                            collection($config:data-root)//tei:persName[@ref = $id]
                }
        else
            ()
};

(:~
    Output the actual search result as a div, using the kwic module to summarize full text matches.
:)
declare
    %templates:wrap
    %templates:default("start", 1)
    %templates:default("per-page", 10)
function query:show-hits($node as node()*, $model as map(*), $start as xs:integer, $per-page as xs:integer, $view as xs:string?) {
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
                        let $id := util:node-id(
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
            if ($config?view = "page") then
                let $contextNode := util:node-by-id($div, $matchId)
                let $page := $contextNode/preceding::tei:pb[1]
                return
                    util:node-id($page)
            else
                util:node-id($div)
        let $action := if (exists($model?ids)) then "" else "search"
        let $config := <config width="60" table="yes" link="{$docId}?root={$docLink}&amp;action={$action}&amp;view={$config?view}&amp;odd={$config?odd}#{$matchId}"/>
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
            case element(tei:term) | element(tei:placeName) | element(tei:persName) return
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
