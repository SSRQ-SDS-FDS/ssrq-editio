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

declare variable $query:QUERY_OPTIONS :=
    <options>
        <leading-wildcard>yes</leading-wildcard>
        <filter-rewrite>yes</filter-rewrite>
    </options>;

(:~
 : Execute query. Dispatches the query to either query:query-texts or query:query-api depending on $type.
 :)
declare
    %templates:default("type", "text")
function query:query($node as node()*, $model as map(*), $type as xs:string, $subtype as xs:string*, $query as xs:string?, $doc as xs:string*,
    $sort as xs:string?) as map(*) {
    if (empty($subtype)) then
        let $sortOrder := session:get-attribute("ssrq.sort")
        return
            map {
                "hits" :
                    if (empty($sort) or $sortOrder = $sort) then
                        session:get-attribute("ssrq.sort")
                    else (
                        query:sort(session:get-attribute("ssrq"), $sort),
                        session:set-attribute("ssrq.sort", $sort)
                ),
                "ids": session:get-attribute("ssrq.ids"),
                "hitCount" : session:get-attribute("ssrq.hitCount"),
                "query" : session:get-attribute("ssrq.query"),
                "docs": session:get-attribute("ssrq.docs")
            }
    else
        let $hits :=
            if ($query) then
                switch ($type)
                    case "text" return
                        query:query-texts($subtype, $query)
                    default return
                        query:query-api($type, $subtype, $query)
            else map {
                "hits": query:filter(collection($config:data-root)/tei:TEI//tei:body)
            }
        let $hitCount := count($hits?hits)
        let $hitsToShow := query:sort($hits?hits, $sort)
        (:Store the result in the session.:)
        let $store := (
            session:set-attribute("ssrq", $hitsToShow),
            session:set-attribute("ssrq.hitCount", $hitCount),
            session:set-attribute("ssrq.query", $query),
            session:set-attribute("ssrq.type", $type),
            session:set-attribute("ssrq.subtype", $subtype),
            session:set-attribute("ssrq.docs", $doc),
            session:set-attribute("ssrq.sort", $sort),
            request:get-parameter-names()[starts-with(., 'filter-')] ! session:set-attribute("ssrq." || ., request:get-parameter(., ()))
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

(:~
 : Editionstext durchsuchen
 :)
declare function query:query-texts($subtypes as xs:string*, $query as xs:string) {
    let $hits :=
        for $subtype in $subtypes
        return
            switch ($subtype)
                case "title" return
                    collection($config:data-root)//tei:teiHeader//tei:msDesc/tei:head[ft:query(., $query, $query:QUERY_OPTIONS)]
                case "regest" return
                    collection($config:data-root)//tei:teiHeader//tei:msContents/tei:summary[ft:query(., $query, $query:QUERY_OPTIONS)]
                case "comment" return
                    collection($config:data-root)//tei:back[ft:query(., $query, $query:QUERY_OPTIONS)]
                case "notes" return
                    collection($config:data-root)//tei:body//tei:note[ft:query(., $query, $query:QUERY_OPTIONS)] |
                    collection($config:data-root)//tei:back//tei:note[ft:query(., $query, $query:QUERY_OPTIONS)]
                case "seal" return
                    collection($config:data-root)//tei:teiHeader//tei:msDesc/tei:physDesc/tei:sealDesc/tei:seal[ft:query(., $query, $query:QUERY_OPTIONS)]
                (: Editionstext: body + orig in Kommentar und Fussnoten :)
                default return
                    collection($config:data-root)//tei:body[ft:query(., $query, $query:QUERY_OPTIONS)] |
                    collection($config:data-root)//tei:back[.//tei:orig[ft:query(., $query, $query:QUERY_OPTIONS)]] |
                    collection($config:data-root)//tei:body[.//tei:note//tei:orig[ft:query(., $query, $query:QUERY_OPTIONS)]]
    return
        map {
            "hits":
                for $hit in query:filter($hits)
                order by ft:score($hit) descending
                return $hit
        }
};

(:~
 : Sachregister durchsuchen über externe API
 :)
declare function query:query-api($type as xs:string, $subtypes as xs:string*, $query as xs:string) as map(*) {
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
                        query:filter(
                            query:api-filter-subtype($ids, $type, $subtypes)
                        )
                }
        else
            console:log($response[1])
};

(:~
 : Filter api search result depending on subtype. All filters are applied in sequence.
 :)
declare function query:api-filter-subtype($id as xs:string*, $type as xs:string, $subtypes as xs:string*) {
    if ($type = "keywords") then
        collection($config:data-root)/tei:TEI[tei:teiHeader/tei:profileDesc/tei:textClass/tei:keywords/tei:term/@ref = $id]//tei:body
    else
        for $subtype in $subtypes
        return
            switch ($subtype)
                case "title" return
                    collection($config:data-root)//tei:teiHeader//tei:msDesc/tei:head/
                        (descendant::tei:placeName|descendant::tei:term|descendant::tei:persName|descendant::tei:orgName)[@ref = $id]
                case "regest" return
                    collection($config:data-root)//tei:teiHeader//tei:msDesc/tei:msContents/tei:summary/
                        (descendant::tei:placeName|descendant::tei:term|descendant::tei:persName|descendant::tei:orgName)[@ref = $id]
                case "comment" return
                    collection($config:data-root)//tei:back[
                        (descendant::tei:placeName|descendant::tei:term|descendant::tei:persName|descendant::tei:orgName)/@ref = $id]
                case "notes" return
                    collection($config:data-root)/(descendant::tei:body|descendant::tei:back)//tei:note/
                        (descendant::tei:placeName|descendant::tei:term|descendant::tei:persName|descendant::tei:orgName)[@ref = $id]
                case "seal" return
                    collection($config:data-root)//tei:teiHeader//tei:msDesc/tei:physDesc/tei:sealDesc/tei:seal/tei:persName[@ref = $id]
                (: Editionstext: body + orig in Kommentar und Fussnoten :)
                default return
                    collection($config:data-root)//tei:body[
                        (descendant::tei:placeName|descendant::tei:term|descendant::tei:persName|descendant::tei:orgName)/@ref = $id] |
                    collection($config:data-root)//tei:back[.//tei:orig/
                        (descendant::tei:placeName|descendant::tei:term|descendant::tei:persName|descendant::tei:orgName)/@ref = $id] |
                    collection($config:data-root)//tei:body[.//tei:note//tei:orig/
                        (descendant::tei:placeName|descendant::tei:term|descendant::tei:persName|descendant::tei:orgName)/@ref = $id] |
                    collection($config:data-root)//tei:body[.//@scribe = $id]
};

(:~
 : Apply filters to the query result.
 :)
declare function query:filter($hits as element()*) {
    fold-right(request:get-parameter-names()[starts-with(., 'filter-')], $hits, function($filter, $context) {
        let $value := filter(request:get-parameter($filter, ()), function($param) { $param != "" })
        return
            if (exists($value)) then
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
                        if ($value = "yes") then
                            $context[ancestor-or-self::tei:TEI//tei:supportDesc/tei:condition]
                        else
                            $context[not(ancestor-or-self::tei:TEI//tei:supportDesc/tei:condition)]
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
                        for $v in $value
                        return
                            $context[ancestor-or-self::tei:TEI[starts-with(tei:teiHeader//tei:seriesStmt/tei:idno/@xml:id, $v || "_")]]
                    case "filter-pubdate-min" return
                        let $dateMin := xs:date($value || "-01-01")
                        return
                            $context[ancestor-or-self::tei:TEI//tei:publicationStmt/tei:date[@type='electronic']/@when >= $dateMin]
                    case "filter-pubdate-max" return
                        let $dateMax := xs:date($value || "-01-01")
                        return
                            $context[ancestor-or-self::tei:TEI//tei:publicationStmt/tei:date[@type='electronic'][@when <= $dateMax]]
                    case "filter-archive" return
                        $context[starts-with(ancestor-or-self::tei:TEI//tei:teiHeader//tei:msDesc/tei:msIdentifier/tei:idno, $value)]
                    case "filter-filiation" return
                        for $node in $context
                        let $idno := $node/ancestor-or-self::tei:TEI//tei:teiHeader//tei:msDesc/tei:msIdentifier/tei:idno
                        let $filiations :=
                            collection($config:data-root)//tei:teiHeader//tei:filiation/tei:idno[. = $idno]
                        let $log := console:log(($idno, count($filiations)))
                        return
                            if ($value = "yes" and exists($filiations)) then
                                $node
                            else if ($value = "no" and empty($filiations)) then
                                $node
                            else
                                ()
                    default return
                        $context
            else
                $context
    })
};

(:~
 : Highlight matches when viewing document after search.
 :)
declare function query:highlight($action as xs:string?, $context as element()*, $subtype as xs:string?, $sr as xs:string*) {
    if ($action = "search") then
        let $query := session:get-attribute("ssrq.query")
        let $type := session:get-attribute("ssrq.type")
        let $subtypes := session:get-attribute("ssrq.subtype")
        let $subtype :=
            if ($subtype) then
                if (index-of($subtypes, $subtype)) then
                    $subtype
                else
                    ()
            else
                $subtypes
        return
            if (exists($subtype)) then
                switch ($type)
                    case "text" return
                        util:expand(query:highlight-texts($context, $subtype, $query), "add-exist-id=all")
                    default return
                        let $highlighted := query:highlight-annotations($context, $sr)
                        return
                            $highlighted
            else
                $context
    else
        $context
};

(:~
 : Highlight fulltext matches
 :)
declare function query:highlight-texts($context as element()*, $subtypes as xs:string*, $query as xs:string) {
    for $subtype in $subtypes
    return
        switch ($subtype)
            case "title" case "seal" return
                $context | $context[ft:query(., $query, $query:QUERY_OPTIONS)]
            case "regest" case "comment" return
                $context | $context[ft:query(., $query, $query:QUERY_OPTIONS)]
            case "notes" return
                $context |
                $context[./descendant-or-self::tei:body//tei:note[ft:query(., $query, $query:QUERY_OPTIONS)]] |
                $context[./descendant-or-self::tei:back//tei:note[ft:query(., $query, $query:QUERY_OPTIONS)]]
            (: Editionstext: body + orig in Kommentar und Fussnoten :)
            case "edition" return
                $context |
                $context[./descendant-or-self::tei:body[ft:query(., $query, $query:QUERY_OPTIONS)]] |
                $context[./descendant-or-self::tei:back//tei:orig[ft:query(., $query, $query:QUERY_OPTIONS)]] |
                $context[./descendant-or-self::tei:body//tei:note//tei:orig[ft:query(., $query, $query:QUERY_OPTIONS)]]
            default return
                ()
};

(:~
 : Highlight places, persons, terms ...
 :)
declare function query:highlight-annotations($nodes as node()*, $ids as xs:string*) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(tei:persName) | element(tei:placeName) | element(tei:orgName) | element(tei:term) return
                element { node-name($node) } {
                    $node/@*,
                    if ($node/@ref = $ids) then
                        <exist:match exist:id="{util:node-id($node)}">{ query:highlight-annotations($node/node(), $ids) }</exist:match>
                    else
                        query:highlight-annotations($node/node(), $ids)
                }
            case element(tei:ab) | element(tei:add) | element(tei:addSpan) | element(tei:handShift) return
                element { node-name($node) } {
                    $node/@*,
                    if ($node/@scribe = $ids) then
                        <exist:match exist:id="{util:node-id($node)}">{ query:highlight-annotations($node/node(), $ids) }</exist:match>
                    else
                        query:highlight-annotations($node/node(), $ids)
                }
            case element() return
                element { node-name($node) } {
                    $node/@*,
                    query:highlight-annotations($node/node(), $ids)
                }
            default return $node
};


(:~
    Output the actual search result as a div, using the kwic module to summarize full text matches.
:)
declare
    %templates:wrap
    %templates:default("start", 1)
    %templates:default("per-page", 10)
function query:show-hits($node as node()*, $model as map(*), $start as xs:integer, $per-page as xs:integer, $view as xs:string?) {
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
        <div class="reference">
            <h5><span class="number">{$start + $p - 1}</span>
                <span class="badge">{query:category($hit)}</span>
                Kanton: <span>{query:view-kanton($work)}</span>,
                Stück: <span>{query:view-idno($work)}</span>, Datum: <span>{query:view-origDate($work)}</span>
            </h5>
            <h4>{query:view-header($work, $parent-id)}</h4>
        </div>
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
        let $config :=
            if (exists($model?ids)) then
                let $idList := string-join(for $id in $model?ids return "sr=" || $id, "&amp;")
                return
                    <config width="60" table="no"
                        link="{$docId}?view={$config?view}&amp;action=search&amp;odd={$config?odd}&amp;{$idList}#{$matchId}"/>
            else
                <config width="60" table="no"
                    link="{$docId}?root={$docLink}&amp;action=search&amp;view={$config?view}&amp;odd={$config?odd}#{$matchId}"/>
        return
            kwic:get-summary($expanded, $match, $config)
    )
};

declare function query:category($hit as element()) {
    typeswitch($hit)
        case element(tei:head) return "Titel"
        case element(tei:summary) return "Regest"
        case element(tei:note) return "Anmerkung"
        case element(tei:back) return "Kommentar"
        case element(tei:seal) return "Siegel"
        default return "Editionstext"
};

declare function query:sort($result as element()*, $sortBy as xs:string?) {
    let $fn := query:sort-value(?, $sortBy)
    for $item in $result
    order by $fn($item)
    return
        $item
};

declare function query:sort-value($item as element(), $sortBy as xs:string?) {
    switch($sortBy)
        case "kanton" return
            replace(root($item)//tei:teiHeader//tei:seriesStmt/tei:idno/@xml:id, "^([^_]+).*$", "$1")
        case "title" return
            let $header := root($item)//tei:teiHeader
            return
                ($header//tei:msDesc/tei:head/string(), $header//tei:titleStmt/tei:title/string())[1]
        case "id" return
            root($item)//tei:teiHeader/tei:fileDesc/tei:seriesStmt/tei:idno/@xml:id
        case "date" return
            root($item)//tei:teiHeader/tei:fileDesc//tei:msDesc/tei:history//tei:origDate/@when/xs:date(.)
        default return
            ft:score($item)
};

declare function query:view-header($work as element(), $parent-id as xs:string) {
    let $header := $work//tei:teiHeader
    let $head := ($header//tei:msDesc/tei:head/node(), $header//tei:titleStmt/tei:title/node())[1]
    return
        <a href="{$parent-id}">{$pm-config:web-transform($head, map { "root": $head }, $config:odd)}</a>
};

declare function query:view-kanton($work as element()) {
    replace($work//tei:teiHeader//tei:seriesStmt/tei:idno/@xml:id, "^([^_]+).*$", "$1")
};

declare function query:view-idno($work as element()) {
    let $header := $work//tei:teiHeader
    let $idno := $header/tei:fileDesc/tei:seriesStmt/tei:idno/@xml:id
    return (
        common:display-sigle($idno),
        $header/tei:fileDesc//tei:msDesc/tei:history//tei:origDate/@when/string(),
        "(provisorisch)"
    )
};

declare function query:view-origDate($work as element()) {
    let $origDate := $work//tei:teiHeader/tei:fileDesc//tei:msDesc/tei:history//tei:origDate/@when
    return
        format-date(xs:date($origDate), '[Y] [MNn] [D01]')
};

(:~
 : Wrap terms, places or persons found via external API search into an exist:match so they are shown
 : in the kwic display.
 :)
declare function query:expand($nodes as node()*, $ids as xs:string+) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(tei:term) | element(tei:placeName) | element(tei:persName) | element(tei:orgName) return
                element { node-name($node) } {
                    $node/@*,
                    if ($node/@ref = $ids) then (
                        attribute exist:id { util:node-id($node) },
                        <exist:match>{ query:expand($node/node(), $ids) }</exist:match>
                    ) else
                        query:expand($node/node(), $ids)
                }
            case element(tei:ab) | element(tei:add) | element(tei:addSpan) | element(tei:handShift) return
                element { node-name($node) } {
                    $node/@*,
                    if ($node/@scribe = $ids) then (
                        attribute exist:id { util:node-id($node) },
                        <exist:match>{ query:expand($node/node(), $ids) }</exist:match>
                    ) else
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
function query:pubdate-range($node as node(), $model as map(*)) {
    let $context :=
        if ($model?hits) then
            $model?hits ! root(.)
        else
            collection($config:data-root)
    let $dates :=
        for $when in $context//tei:teiHeader//tei:publicationStmt/tei:date[@type='electronic']/@when
        return
            try {
                year-from-date(xs:date($when))
            } catch * {
                if (matches($when, "^\d+$")) then
                    number($when)
                else
                    ()
            }
    return
        map {
            "min": min($dates),
            "max": max($dates)
        }
};


declare
    %templates:wrap
function query:list-archives($node as node(), $model as map(*), $filter-archive as xs:string?) {
    $node/*,
    let $context :=
        if ($model?hits) then
            $model?hits ! root(.)
        else
            collection($config:data-root)
    for $idno in distinct-values(
            for-each($context//tei:teiHeader//tei:msDesc/tei:msIdentifier/tei:idno, function($id) {
                replace($id, "^(\w+).*$", "$1")
            })
        )
    return
        <option>
        {
            if ($idno = $filter-archive) then
                attribute selected { "selected" }
            else
                ()
        }
        {$idno}
        </option>
};
