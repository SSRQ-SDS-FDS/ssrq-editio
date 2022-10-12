xquery version "3.1";

module namespace query="http://ssrq-sds-fds.ch/exist/apps/ssrq/search";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace i18n="http://exist-db.org/xquery/i18n";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace http="http://expath.org/ns/http-client";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xqm";
import module namespace kwic="http://exist-db.org/xquery/kwic";
import module namespace nav="http://www.tei-c.org/tei-simple/navigation" at "navigation.xqm";
import module namespace app="http://ssrq-sds-fds.ch/exist/apps/ssrq/app" at "ssrq.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xqm";
import module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common" at "ext-common.xqm";
import module namespace intl="http://exist-db.org/xquery/i18n/templates" at "lib/i18n-templates.xqm";
import module namespace functx="http://www.functx.com";
import module namespace data-filters="http://ssrq-sds-fds.ch/exist/apps/ssrq-data/filters" at "/db/apps/ssrq-data/modules/filters.xqm";
import module namespace doc-list="http://ssrq-sds-fds.ch/exist/apps/ssrq-data/doc-list" at "/db/apps/ssrq-data/modules/doc-list.xqm";
import module namespace ssrq-helper="http://ssrq-sds-fds.ch/exist/apps/ssrq/helper" at "ssrq-helper.xqm";

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
    $sort as xs:string?, $refresh as xs:boolean?) as map(*) {
    if (empty($refresh)) then
        let $sortOrder := session:get-attribute("ssrq.sort")
        return
            map {
                "hits" :
                    if (empty($sort) or $sortOrder = $sort) then
                        session:get-attribute("ssrq")
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
                case "idno" return
                    collection($config:data-root)//tei:teiHeader//tei:msDesc/tei:msIdentifier/tei:idno[ft:query(., $query, $query:QUERY_OPTIONS)]
                case "regest" return
                    collection($config:data-root)//tei:teiHeader//tei:msContents/tei:summary[ft:query(., $query, $query:QUERY_OPTIONS)]
                case "comment" return
                    collection($config:data-root)//tei:back[ft:query(., $query, $query:QUERY_OPTIONS)]
                case "notes" return
                    collection($config:data-root)//tei:body//tei:note[ft:query(., $query, $query:QUERY_OPTIONS)] |
                    collection($config:data-root)//tei:back//tei:note[ft:query(., $query, $query:QUERY_OPTIONS)]
                case "seal" return
                    collection($config:data-root)//tei:teiHeader//tei:msDesc/tei:physDesc/tei:sealDesc/tei:seal[ft:query(., $query, $query:QUERY_OPTIONS)]
                case "literature" return
                    collection($config:data-root)//tei:teiHeader//tei:msDesc//tei:listBibl[ft:query(., $query, $query:QUERY_OPTIONS)]
                (: Editionstext: body + orig in Kommentar und Fussnoten :)
                default return
                    collection($config:data-root)//tei:body[*][not(@type="volinfo")][ft:query(., $query, $query:QUERY_OPTIONS)] |
                    collection($config:data-root)//tei:back[.//tei:orig[ft:query(., $query, $query:QUERY_OPTIONS)]] |
                    collection($config:data-root)//tei:body[*][not(@type="volinfo")][.//tei:note//tei:orig[ft:query(., $query, $query:QUERY_OPTIONS)]]

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
        <http:request method="GET" href="{$url}{encode-for-uri($query)}">
            <http:header name="User-Agent" value="{$config:user-agent}"/>
        </http:request>
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
            (: let $log := util:log("info", "IDs: " || string-join($ids, ', ')) :)
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
        collection($config:data-root)/tei:TEI[tei:teiHeader/tei:profileDesc/tei:textClass/tei:keywords/tei:term/@ref = $id]/tei:text |
        collection($config:data-root)/tei:TEI/tei:text[descendant::tei:term/@ref = $id]
    else
        for $subtype in $subtypes
        return
            switch ($subtype)
                case "title" return
                    collection($config:data-root)//tei:teiHeader//tei:msDesc/tei:head/
                        (descendant::tei:placeName|descendant::tei:term|descendant::tei:persName|descendant::tei:orgName)[substring(@ref, 1, 9) = $id]
                case "regest" return
                    collection($config:data-root)//tei:teiHeader//tei:msDesc/tei:msContents/tei:summary/
                        (descendant::tei:placeName|descendant::tei:term|descendant::tei:persName|descendant::tei:orgName)[substring(@ref, 1, 9) = $id]
                case "comment" return
                    collection($config:data-root)//tei:back[
                        (descendant::tei:placeName|descendant::tei:term|descendant::tei:persName|descendant::tei:orgName)[substring(@ref, 1, 9) = $id]]
                case "notes" return
                    collection($config:data-root)/(descendant::tei:body|descendant::tei:back)//tei:note/
                        (descendant::tei:placeName|descendant::tei:term|descendant::tei:persName|descendant::tei:orgName)[substring(@ref, 1, 9) = $id]
                case "seal" return
                    collection($config:data-root)//tei:teiHeader//tei:msDesc/tei:physDesc/tei:sealDesc/tei:seal/tei:persName[substring(@ref, 1, 9) = $id]
                (: Editionstext: body + orig in Kommentar und Fussnoten :)
                default return
                    collection($config:data-root)//tei:body[
                        (descendant::tei:placeName|descendant::tei:term|descendant::tei:persName|descendant::tei:orgName)[substring(@ref, 1, 9) = $id]] |
                    collection($config:data-root)//tei:back[.//tei:orig/
                        (descendant::tei:placeName|descendant::tei:term|descendant::tei:persName|descendant::tei:orgName)[substring(@ref, 1, 9) = $id]] |
                    collection($config:data-root)//tei:body[.//tei:note//tei:orig/
                        (descendant::tei:placeName|descendant::tei:term|descendant::tei:persName|descendant::tei:orgName)[substring(@ref, 1, 9) = $id]] |
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
                                $context[substring(ancestor-or-self::tei:TEI//tei:history/tei:origin/tei:origDate/@when, 1, 4) >= $value]
                        case "filter-period-max" return
                                $context[substring(ancestor-or-self::tei:TEI//tei:history/tei:origin/tei:origDate/@when, 1, 4) <= $value]
                        case "filter-language" return
                            $context[ancestor-or-self::tei:TEI//tei:textLang/@xml:lang = $value]
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
                                $context[ancestor-or-self::tei:TEI[matches(tei:teiHeader//tei:seriesStmt/tei:idno, ``[^(?:SSRQ|SDS|FDS)-`{$v}`.*$]``)]]
                        case "filter-pubdate-min" return
                                $context[substring(ancestor-or-self::tei:TEI//tei:publicationStmt/tei:date[@type='electronic']/@when, 1, 4) >= $value]
                        case "filter-pubdate-max" return
                                $context[substring(ancestor-or-self::tei:TEI//tei:publicationStmt/tei:date[@type='electronic']/@when, 1, 4) <= $value]
                        case "filter-pubplace" return
                            if ($value = "yes") then
                                $context[ancestor-or-self::tei:TEI//tei:history/tei:origin/tei:origPlace]
                            else
                                $context[not(ancestor-or-self::tei:TEI//tei:history/tei:origin/tei:origPlace)]
                        case "filter-archive" return
                            $context[contains(ancestor-or-self::tei:TEI//tei:teiHeader//tei:msDesc/tei:msIdentifier/tei:idno, $value)]
                        default return
                            $context
                else
                    $context
        })
};


(:~ Note: Never really worked – see #2568
: To-Do: Reimplement query-highlight, which is used by app.xqm
:)

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
            case "title" case "idno"
            case "regest" case "comment"
            case "seal" return
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
                    if (substring($node/@ref, 1, 9) = $ids) then
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
function query:show-hits($node as node()*, $model as map(*), $start as xs:integer, $per-page as xs:integer, $view as xs:string?, $lang as xs:string?) as element(div)* {
    for $hit at $index in $model?hits => subsequence($start, $per-page)
    let $work := $hit/ancestor::tei:TEI
    let $config := tpu:parse-pi(root($work), $view)
    let $relpath :=
        try {
            let $doc := doc-list:get($work//tei:seriesStmt/tei:idno[1])
            return
                ec:create-app-link((
                    $doc/kanton,
                    $doc/volume,
                    if ($doc/special) then
                        $doc/special
                    else
                        (string-join(($doc/case, $doc/doc), '.'), $doc/num) => string-join('-')
                    || '.html'))
        } catch * {
            ()
        }
    where $relpath
    return
        <div class="reference">
            {query:view-header($work, $relpath, $hit, $start, $index)}
            {query:view-snippets($hit, $model, $config, $relpath)}
        </div>
};

declare function query:category($hit as element()) {
    typeswitch($hit)
        case element(tei:head) return "title"
        case element(tei:idno) return "idno"
        case element(tei:summary) return "regest"
        case element(tei:note) return "notes"
        case element(tei:back) return "comment"
        case element(tei:seal) return "seal"
        default return "editionText"
};

declare function query:sort($items as element()*, $sortBy as xs:string?) {
    switch($sortBy)
        case "kanton" return
            for $item in $items
            order by query:view-kanton($item)
            return
                $item
        case "title" return
            for $item in $items
            let $header := root($item)//tei:teiHeader
            order by
                ($header//tei:msDesc/tei:head/string(), $header//tei:titleStmt/tei:title/string())[1]
            return
                $item
        case "relevance" return
            for $item in $items
            order by ft:score($item)
            return
                $item
        default return (: id :)
            for $item in $items
            order by query:get-ssrq-idno($item, ("sort", "human", "machine"))
            return
                $item
};

declare %private
function query:get-ssrq-idno($work, $preferred-types) {
    let $seriesStmt := $work//tei:teiHeader//tei:seriesStmt
    return (
        (: preferred types first :)
        for $ptype in $preferred-types
        return $seriesStmt/tei:idno[@type=$ptype],

        (: otherwise, any idno :)
        $seriesStmt/tei:idno[1]
    )[1]/text()
};

declare %private
function query:get-ssrq-idno($work) {
    query:get-ssrq-idno($work, ())
};

declare
    %private
function query:view-header($work as node(), $relpath as xs:string, $hit as item(), $start as xs:integer, $index as xs:integer) as element(header) {
    let $header := $work//tei:teiHeader
    let $head := ($header//tei:msDesc/tei:head/node(), $header//tei:titleStmt/tei:title/node())[1]
    return
        <header>
            <h5>
                <span class="number">{$start + $index - 1}</span>
                <span class="badge ml-0"><i18n:text key="{query:category($hit)}"/></span>
                <i18n:text key="canton">Kanton</i18n:text>: <span>{query:view-kanton($work)}</span>,
                <i18n:text key="work-id">Stück</i18n:text>: <span>{query:view-idno($work)}</span>,
                <i18n:text key="orig-date">Datum</i18n:text>: <span>{query:view-origDate($work)}</span>
            </h5>
            <h4>
                <a href="{$relpath}">{$pm-config:web-transform($head, map { "root": $head}, $config:odd)}</a>
            </h4>
        </header>
};

declare
    %private
function query:view-snippets($hit as item(), $model as map(*), $config as map(*), $relpath as xs:string) as element(article) {
    let $mark-matches :=
        if (exists($model?ids)) then
            let $parent := ($hit/self::tei:body, $hit/ancestor-or-self::tei:div[1],  $hit/ancestor-or-self::tei:teiHeader, $hit)[1]
            return
                query:expand($parent, $model?ids)
        else
            util:expand($hit, "add-exist-id=all")
    return
        <article>
            {
            for $match in subsequence($mark-matches//exist:match, 1, 5)
            let $matchId := $match/../@exist:id
            let $action := if (exists($model?ids)) then "" else "search"
            let $kwic-config :=
                if (exists($model?ids)) then
                    let $idList := string-join(for $id in $model?ids return "sr=" || $id, "&amp;")
                    return
                        <config width="60" table="no"
                            link="{$relpath}?view={$config?view}&amp;action=search&amp;odd={$config?odd}&amp;{$idList}#{$matchId}"/>
                else
                    <config width="60" table="no"
                        link="{$relpath}?root=body&amp;action=search&amp;view={$config?view}&amp;odd={$config?odd}#{$matchId}"/>
            return
                kwic:get-summary($mark-matches, $match, $kwic-config)
            }
        </article>
};

declare function query:view-kanton($work as element()) {
    let $idno := query:get-ssrq-idno($work, ("machine", "human"))
    return replace($idno, "^(?:SSRQ|SDS|FDS)[-_ ]([A-Z]{2})[-_ ].*$", "$1")
};

declare function query:view-idno($work as element()) {
    query:get-ssrq-idno($work, ("machine")) => ec:format-id()
};

declare function query:view-origDate($work as element()) {
    let $origDate := $work//tei:teiHeader/tei:fileDesc//tei:msDesc/tei:history//tei:origDate
    let $lang := $config:lang-settings?lang
    return
        (
          (if ($origDate/@when) then
             $origDate/@when
           else
             ($origDate/@from, $origDate/@to)
          ) ! format-date(xs:date(.), '[Y] [MNn] [D01]', $lang, (), ())
        ) => string-join("-")
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
                    if (substring($node/@ref, 1, 9) = $ids) then (
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

declare
function query:period-range($node as node(), $model as map(*)) {
    if ($model?hits) then
        data-filters:period-range($model?hits ! root(.))
    else
        data-filters:period-range()
};

declare
function query:pubdate-range($node as node(), $model as map(*)) {
    if ($model?hits) then
        data-filters:pubdate-range($model?hits ! root(.))
    else
        data-filters:pubdate-range()
};

declare
    %templates:wrap
function query:list-archives($node as node(), $model as map(*), $filter-archive as xs:string?) {
    $node/*,
    let $archives :=
        if ($model?hits) then
            data-filters:archive-list($model?hits ! root(.))
        else
            data-filters:archive-list()
    for $archive-title in $archives
    return
        <option>
            {
                if ($archive-title = $filter-archive) then
                    attribute selected { "selected" }
                else
                    ()
            }
            {$archive-title}
        </option>
};
