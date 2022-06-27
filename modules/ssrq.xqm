xquery version "3.1";

module namespace app="http://ssrq-sds-fds.ch/exist/apps/ssrq/app";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xqm";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xqm";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xqm";
import module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common" at "/db/apps/ssrq/modules/ext-common.xqm";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace query="http://ssrq-sds-fds.ch/exist/apps/ssrq/search" at "ssrq-search.xqm";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "lib/pages.xqm";
import module namespace http="http://expath.org/ns/http-client" at "java:org.expath.exist.HttpClientModule";
import module namespace doc-list="http://ssrq-sds-fds.ch/exist/apps/ssrq-data/doc-list" at "/db/apps/ssrq-data/modules/doc-list.xqm";
import module namespace ssrq-helper="http://ssrq-sds-fds.ch/exist/apps/ssrq/helper" at "ssrq-helper.xqm";

import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "utils.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $app:single-body-div-max := 7;

declare variable $app:HOST := "https://www.ssrq-sds-fds.ch";

declare variable $app:PLACES := $app:HOST || "/places-db-edit/views/get-infos.xq";
declare variable $app:PERSONS := $app:HOST || "/persons-db-api/";
declare variable $app:LEMMA := $app:HOST || "/lemma-db-edit/views/get-lem-infos.xq";
declare variable $app:KEYWORDS := $app:HOST || "/lemma-db-edit/views/get-key-infos.xq";


declare function app:failed-to-load($id as xs:string) as element(TEI) {
    (
        trace('Loading of ' || $id || ' failed'),
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
                        <p>Could not load document with the id '{$id}'. Maybe it is not valid TEI or not in the TEI namespace?</p>
                    </div>
                </body>
            </text>
        </TEI>
    )[2]
};

declare
    %templates:wrap
function app:load($node as node(), $model as map(*), $doc as xs:string, $root as xs:string?,
    $id as xs:string?, $view as xs:string?) {
    let $doc := xmldb:decode($doc)
    let $result :=
        if ($id) then
            let $tei :=
                utils:coalesce(
                    collection($config:data-root)/tei:TEI[tei:teiHeader//tei:seriesStmt/tei:idno = $id],
                    collection($config:data-root)/tei:TEI[tei:teiHeader//tei:seriesStmt/tei:idno = $id || "_1"]
                )
            let $data :=
                app:query-view($tei/tei:text, utils:coalesce($view, $config:default-view))
            let $config :=
                if ($data) then
                    tpu:parse-pi(root($data), $view)
                else
                    ()
            return
                map {
                    "config": $config,
                    "data": $data
                }
        else
            pages:load-xml($view, $root, $doc)
    let $has-facs := exists($result?data//tei:pb[@facs]) and $result?config?odd = "ssrq.odd"
    return
        map {
            "config": $result?config,
            "data": utils:coalesce(
                $result?data,
                app:failed-to-load($doc)),
            "doc-type": $result?data/ancestor::tei:TEI/@type/data(.),
            "body-class": if ($has-facs) then 'col-md-6' else 'col-md-10',
            "facs-class": if ($has-facs) then 'col-md-6' else 'hidden',
            "sidebar-class": if ($has-facs) then 'hidden' else 'col-md-2'
        }
};

declare function app:query-view($context as node(), $view as xs:string?) as node()* {
    switch ($view)
        case 'body'
           return $context//tei:body
        case 'back'
            return $context//tei:back
        case 'group'
            return $context//tei:group
        default
            return $context
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

declare function app:api-lookup($api as xs:string, $list as map(*)*, $param as xs:string) {
    let $lang := (session:get-attribute("ssrq.lang"), "de")[1]
    let $iso-639-3 :=
    map {
        'de'     : 'deu',
        'fr'     : 'fra',
        'it'     : 'ita',
        'en'     : 'eng'
    }
    let $refs := string-join(for $item in $list return $item?ref, ",")
    let $request :=
        <http:request method="GET" href="{$api}?{$param}={$refs}&amp;lang={$iso-639-3($lang)}">
            <http:header name="User-Agent" value="{$config:user-agent}"/>
        </http:request>
    let $response := http:send-request($request)
    return
        if ($response[1]/@status = "200") then
            let $json := parse-json(util:binary-to-string($response[2]))
            return
                $json?info
        else
            ()
};

declare function app:api-lookup-xml($api as xs:string, $list as map(*)*, $param as xs:string) {
    let $lang := (session:get-attribute("ssrq.lang"), "de")[1]
    let $iso-639-3 :=
    map {
        'de'     : 'deu',
        'fr'     : 'fra',
        'it'     : 'ita',
        'en'     : 'eng'
    }
    let $refs := string-join(for $item in $list return $item?ref, ",")
    let $request := <http:request method="GET" href="{$api}?{$param}={$refs}&amp;lang={$iso-639-3($lang)}"/>
    let $response := http:send-request($request)
    return
        if ($response[1]/@status = "200") then
            $response[2]
        else
            ()
};

declare function app:api-keys($refs as xs:string*) {
    for $id in $refs
    group by $ref := substring($id, 1, 9)
    (: group by $ref := replace($id, "^([^\.]+).*$", "$1") :)
    return
        map {
            "ref": $ref,
            "name": $id[1]
        }
};

declare function app:list-places($node as node(), $model as map(*)) {
    let $places := root($model?data)//(tei:placeName[@ref]|tei:origPlace[@ref])
    where exists($places)
    return map {
        "items":
            for $place in app:api-lookup-xml($app:PLACES, app:api-keys($places/@ref), "id")//info
            order by $place/stdName
            return
                <li data-ref="{$place/@id}">
                    <input type="checkbox" class="select-facet" title="i18n(highlight-facet)"></input>
                    <a target="_new" href="https://www.ssrq-sds-fds.ch/places-db-edit/views/view-place.xq?id={$place/@id}">{$place/stdName}</a>
                    ({$place/location})
                    {$place/type}
                </li>
    }
};

declare function app:list-keys($node as node(), $model as map(*)) {
    let $keywords := root($model?data)//tei:term[starts-with(@ref, 'key')]
    where exists($keywords)
    return map {
        "items":
            for $lemma in app:api-lookup-xml($app:KEYWORDS, app:api-keys($keywords/@ref), "id")//info
            order by $lemma/name
            return
                <li data-ref="{$lemma/@id}">
                    <input type="checkbox" class="select-facet" title="i18n(highlight-facet)"/>
                    <a href="https://www.ssrq-sds-fds.ch/lemma-db-edit/views/view-keyword.xq?id={$lemma/@id}" target="_new">{$lemma/name}</a>
                </li>
    }
};

declare function app:list-lemmata($node as node(), $model as map(*)) {
    let $lemmata := root($model?data)//tei:term[starts-with(@ref, 'lem')]
    where exists($lemmata)
    return map {
        "items":
            for $lemma in app:api-lookup-xml($app:LEMMA, app:api-keys($lemmata/@ref), "id")//info
            order by $lemma/stdName
            return
                <li data-ref="{$lemma/@id}">
                    <input type="checkbox" class="select-facet" title="i18n(highlight-facet)"/>
                    <a target="_new" href="https://www.ssrq-sds-fds.ch/lemma-db-edit/views/view-lemma.xq?id={$lemma/@id}">{$lemma/stdName}</a>
                    ({$lemma/morphology})
                    {$lemma/definition}
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
            for $person in app:api-lookup($app:PERSONS, app:api-keys($persons), "ids_search")?*
            order by $person?name
            return
                <li data-ref="{$person?id}">
                    <input type="checkbox" class="select-facet" title="i18n(highlight-facet)"/>
                    <a target="_new" href="https://www.ssrq-sds-fds.ch/persons-db-edit/?query={$person?id}">{$person?name}</a>
                        {
                            if ($person?dates) then
                                <span class="info"> ({$person?dates})</span>
                            else
                                ()
                        }
                </li>
    }
};

declare function app:list-organizations($node as node(), $model as map(*)) {
    let $organizations := root($model?data)//tei:orgName/@ref
    where exists($organizations)
    return map {
        "items":
            for $organization in app:api-lookup($app:PERSONS, app:api-keys($organizations), "ids_search")?*
            order by $organization?name
            return
                <li data-ref="{$organization?id}">
                    <input type="checkbox" class="select-facet" title="i18n(highlight-facet)"/>
                    <a target="_new" href="https://www.ssrq-sds-fds.ch/persons-db-edit/?query={$organization?id}">{$organization?name}</a>
                        {
                            if ($organization?type) then
                                <span class="info"> ({$organization?type})</span>
                            else
                                ()
                        }
                </li>
    }
};

declare
    %templates:wrap
function app:show-list-items($node as node(), $model as map(*)) {
    for $item in $model?items
    order by $item/a collation "?lang=de_CH"
    return
        $item
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
                        collection($config:data-root)/tei:TEI[starts-with(tei:teiHeader//tei:seriesStmt/tei:idno, $current || "_")]
                        [.//tei:text/tei:body/*]
                        |
                        (
                            for $prefix in ("SSRQ_", "SDS_", "FDS_")
                            return
                                collection($config:data-root)/tei:TEI[starts-with(tei:teiHeader//tei:seriesStmt/tei:idno, $prefix || $current)]
                                [.//tei:text/tei:body/*]
                        )
                    )
                    except
                        collection($config:temp-root)/tei:TEI
                let $docs := app:filter-collections($docs)
                return (
                    $tr/td[3]/@*,
                    if (exists($docs)) then
                        <span>
                            <a href="?kanton={$current}&amp;refresh=yes">{$tr/td[3]/node()} </a>
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
declare
    %templates:default("sort", "date")
function app:list-works($node as node(), $model as map(*), $filter as xs:string?, $kanton as xs:string?, $browse as xs:string?,
    $sort as xs:string, $refresh as xs:string?) {
    let $kanton := ($kanton, app:select-kanton())[1]
    let $sessionData :=
        if ($refresh) then
            let $lang := session:get-attribute("ssrq.lang")
            return (
                session:clear(),
                session:set-attribute("ssrq.lang", $lang)
            )
        else
            session:get-attribute("ssrq.works")
    let $log := console:log("Refresh: " || $refresh || "; kanton=" || $kanton || "; count: " || count($sessionData))
    let $filtered :=
        if ($sessionData) then
            $sessionData
        else if ($filter) then
            let $ordered :=
                for $item in
                    ft:search($config:data-root, $browse || ":" || $filter, ("author", "title"))/search
                return
                    $item
            for $doc in $ordered
            return
                doc($doc/@uri)/tei:TEI[matches(tei:teiHeader//tei:seriesStmt/tei:idno, ``[^(?:SSRQ|SDS|FDS)_`{$kanton}`.*$]``)]
                    [.//tei:text/tei:body/*]
        else
            (
                collection($config:data-root)/tei:TEI[starts-with(tei:teiHeader//tei:seriesStmt/tei:idno, $kanton || "_")]
                    [.//tei:text/tei:body/*],
                for $prefix in ("SSRQ_", "SDS_", "FDS_")
                return
                    collection($config:data-root)/tei:TEI[starts-with(tei:teiHeader//tei:seriesStmt/tei:idno, $prefix || $kanton)]
                        [.//tei:text/tei:body/*]
            )
            except
            collection($config:temp-root)/tei:TEI
    let $sorted := query:sort(app:filter-collections($filtered), $sort)
    return (
        session:set-attribute("ssrq.works", $sorted),
        session:set-attribute("ssrq.browse", $browse),
        session:set-attribute("ssrq.filter", $filter),
        session:set-attribute("ssrq.kanton", $kanton),
        session:set-attribute("ssrq.sort", $sort),
        map {
            "all" : $sorted,
            "mode": "browse"
        }
    )
};

declare function app:filter-collections($docs) {
    let $refs := collection($config:data-root)//tei:div[@type='collection']//tei:ref/string()
    return
        $docs except $docs[substring-before(util:document-name(.), ".xml") = $refs]
};


declare function app:home($node as node(), $model as map(*)) {
    templates:process(
        element { node-name($node) } {
            $node/@* except $node/@data-template,
            attribute href {"$app"},
            $node/node()
        },
        $model
    )
};


declare function app:select-kanton() {
    let $first := fold-left(("ZH", "BE", "LU", "UR", "SZ", "OW", "NW", "GL", "ZG", "FR", "SO", "BS", "BL", "SH", "AR", "AI", "SG",
        "GR", "AG", "TG", "TI", "VD", "VS", "NE", "GE", "JU"), (), function($zero, $kanton) {
            if ($zero) then
                $zero
            else if (exists(
                (
                    for $prefix in ("SSRQ_", "SDS_", "FDS_")
                    return
                        collection($config:data-root)/tei:TEI[starts-with(tei:teiHeader//tei:seriesStmt/tei:idno, $prefix || $kanton)]
                )
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

declare function app:header-short($node as node(), $model as map(*)) {
    let $head := $model?xml//tei:teiHeader//tei:msDesc/tei:head
    return
        app:show-if-exists($node, $head, function() {
            $pm-config:web-transform($head, map { "root": $head }, $config:odd)
        })
};


declare function app:idno($node as node(), $model as map(*)) {
    let $header := root($model?data)//tei:teiHeader
    let $idno := $header/tei:fileDesc/tei:seriesStmt/tei:idno
    return
        app:show-if-exists($node, $idno, function() {
            ec:format-id($idno)
        })
};

declare function app:pers-names($header as node() ) {
    let $namen :=  $header/tei:titleStmt/tei:respStmt[tei:resp[@key='transcript' or @key='headerinfo']]/tei:persName/text()
return
    if (count($namen) > 1) then (
        string-join(subsequence($namen, 1, count($namen) -1), ', '),
        <i18n:text xmlns:i18n="http://exist-db.org/xquery/i18n" key="and"> und </i18n:text>,
        $namen[last()]
    ) else
        $namen
};

declare function app:idno-popup($node as node(), $model as map(*)) {
    let $header := root($model?data)//tei:teiHeader/tei:fileDesc
    let $idno := $header/tei:seriesStmt/tei:idno
    let $stmtTitle := $header/tei:seriesStmt/tei:title/text()
    let $fileDescTitle := $header/tei:titleStmt/tei:title
    let $link := "https://www.ssrq-sds-fds.ch/online/tei/" || ec:get-canton($idno) || "/" || util:document-name($model?data)
    return
        app:show-if-exists($node, $idno, function() {
            <span class="alternate">
                <span class="id">{ec:format-id($idno)} <i class="glyphicon glyphicon-info-sign"/></span>
                <span class="altcontent" xmlns:i18n="http://exist-db.org/xquery/i18n" popover-class="increase-popover-width">
                    <p>{$stmtTitle}, {$pm-config:web-transform($fileDescTitle, map { "root": $fileDescTitle, "view": "infopopup"}, $config:odd)}, <i18n:text key="by">von</i18n:text> {app:pers-names($header)}</p>
                    <p><i18n:text key="zitation">Zitation:</i18n:text> <a href="{$link}">{ec:format-id($idno)}</a></p>
                    <p><i18n:text key="lizenz">Lizenz:</i18n:text> <a href="https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode.de">CC BY-NC-SA</a></p>
                </span>
            </span>
        })
};

declare function app:origDate($node as node(), $model as map(*)) {
    let $header := $model?xml//tei:teiHeader
    let $filiation := $header/tei:fileDesc//tei:msDesc/tei:msContents/tei:msItem/tei:filiation[@type='original'][tei:origDate]
    let $origin := $header/tei:fileDesc//tei:msDesc/tei:history/tei:origin
    let $origDate := if (exists($filiation/tei:origDate)) then $filiation/tei:origDate else $origin/tei:origDate
    let $origPlace := if (exists($filiation/tei:origPlace)) then $filiation/tei:origPlace else $origin/tei:origPlace
    return
        app:show-if-exists($node, ($origDate/@when, $origDate/@from), function() {
            replace(ec:print-date($origDate), '\.$', '') || '. ' || string-join($origPlace, ec:semicolon() || ' ')
        })
};

declare function app:comment($node as node(), $model as map(*), $action as xs:string?, $sr as xs:string*) {
    let $back := $model?xml//tei:back
    return
        app:show-if-exists($node, $back, function() {
            templates:process($node/node(), map:merge(($model, map { "data": $back })))
        })
};

declare function app:regest($node as node(), $model as map(*)) {
    let $regest := $model?xml//tei:teiHeader//tei:msContents/tei:summary
    return
        app:show-if-exists($node, $regest, function() {
            templates:process($node/node(), map:merge(($model, map { "data": $regest})))
        })
};

declare
function app:additional-sources($node as node(), $model as map(*)) as element(div)? {
    let $additional-sources :=
        for $header in collection($config:data-root)//tei:teiHeader
            [matches(.//tei:seriesStmt/tei:idno[1], ($model?idno/*[not(name(.) = 'num')]/text(), '\d+') => string-join('-'))]
            [not(.//tei:seriesStmt/tei:idno = $model?idno/@xml:id/data(.))]
        order by $header//tei:seriesStmt/tei:idno[1]
        return
            $header//tei:msDesc
    where exists($additional-sources)
    return
        element { node-name($node)} {
            $node/@* except $node/@data-template,
            templates:process($node/node(), map:merge(($model, map{ "data": $additional-sources})))
        }

};

declare
     %templates:wrap
function app:abbr-blocks($node as node(), $model as map(*)) {
    $pm-config:web-transform($config:abbr//tei:dataSpec, map { "root": $config:abbr//tei:dataSpec}, $config:odd)
};

declare
     %templates:wrap
function app:partners($node as node(), $model as map(*)) {
    let $lang := (session:get-attribute("ssrq.lang"), "de")[1]
    return
        (<h3 xmlns:i18n="http://exist-db.org/xquery/i18n"><i18n:text key="partners">Projektpartner</i18n:text></h3>,
        for $partner in $config:partners//tei:dataSpec[@ident="partners"]/tei:valList/tei:valItem
        let $desc := $partner/tei:desc[@xml:lang=$lang]
        let $value := $desc/tei:p/text()
        order by $value => substring(1, 1) => upper-case()
        return
            <p>
                {
                    if ($desc/tei:ref)
                    then <a href="{$desc/tei:ref}">{$value}</a>
                    else $value
                }
            </p>,
        <h3 xmlns:i18n="http://exist-db.org/xquery/i18n"><i18n:text key="funding">Finanzielle Unterstützung</i18n:text></h3>,
        for $partner in $config:partners//tei:dataSpec[@ident="funding"]/tei:valList/tei:valItem
        let $desc := $partner/tei:desc[@xml:lang=$lang]
        let $value := $desc/tei:p/text()
        order by $value => substring(1, 1) => upper-case()
        return
            <p>
                {
                    if ($desc/tei:ref)
                    then <a href="{$desc/tei:ref}">{$value}</a>
                    else $value
                }
            </p>
        )
};

declare
     %templates:wrap
function app:show-credits($node as node(), $model as map(*)) {
    let $partner := root($model?xml)//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/tei:p[@xml:id="facs"]/text()
    return
        if ($partner) then
            <p xmlns:i18n="http://exist-db.org/xquery/i18n"><i18n:text key="credits"/>{' ' || $partner}</p>
        else
            ()
};

declare
    %templates:wrap
function app:source-description($node as node(), $model as map(*)) {
    let $msDesc := $model?xml//tei:teiHeader//tei:fileDesc/tei:sourceDesc/tei:msDesc
    return
        templates:process($node/node(), map:merge(($model, map { "data": $msDesc })))
};

declare
    %templates:wrap
function app:display-data($node as node(), $model as map(*), $mode as xs:string?) {
    for $data in $model?data
      return
    $pm-config:web-transform($data, map { "root": $data, "mode": $mode, "lang": (session:get-attribute('ssrq.lang'), 'de')[1] }, $config:odd)

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

declare
%templates:wrap
function app:download($node as node(), $model as map(*)) as element(li)? {
    if ($model => map:contains('xml')) then
        <li class="dropdown">
            {
                 templates:process($node/node(), $model)
            }
        </li>
    else ()
};

declare
function app:download-xml($node as node(), $model as map(*)) as element(a) {
    <a href="{ssrq-helper:link-to-resource($model, '.xml')}">
        {
            $node/@*,
            templates:process($node/node(), $model)
        }
    </a>
};

declare
function app:download-pdf($node as node(), $model as map(*)) as element(a)? {
    let $uri := root($model?xml) => document-uri() => tokenize('/')
    let $is-FR := $uri[last()] => contains('FR')
    let $path := utils:path-concat(
        (
            $uri[not(. eq $uri[last()])], 'pdf',
            let $filename := $uri[last()] => replace('.xml', '.pdf')
            return
                (: FR pdfs are bundled into cases and we need to extract and cut the doc-number from the filename :)
                if ($is-FR) then
                    $filename => replace('\.\d+', '')
                else
                    $filename
        )
    )
    return
        <a href="{ssrq-helper:link-to-resource($model, '.pdf', not($is-FR))}">
            {
                $node/@*,
                templates:process($node/node(), $model)
            }
        </a>[util:binary-doc-available($path)]
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
