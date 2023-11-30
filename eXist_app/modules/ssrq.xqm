xquery version "3.1";

module namespace app="http://ssrq-sds-fds.ch/exist/apps/ssrq/app";

import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xqm";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xqm";
import module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common" at "/db/apps/ssrq/modules/ext-common.xqm";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace query="http://ssrq-sds-fds.ch/exist/apps/ssrq/search" at "ssrq-search.xqm";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "lib/pages.xqm";
import module namespace http="http://expath.org/ns/http-client" at "java:org.expath.exist.HttpClientModule";
import module namespace ssrq-helper="http://ssrq-sds-fds.ch/exist/apps/ssrq/helper" at "ssrq-helper.xqm";
import module namespace ssrq-cache="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/cache" at "repository/cache.xqm";

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
            ec:create-link("", map { "odd":
                if (empty($odd) or $odd = $config:odd-diplomatic) then
                    $config:odd-normalized
                else
                     $config:odd-diplomatic
                }, true())
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
    let $lang := $config:lang-settings?lang
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
    let $lang := $config:lang-settings?lang
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

declare
    %templates:wrap
function app:show-list-items($node as node(), $model as map(*)) {
    for $item in $model?items
    order by $item/a collation "?lang=de_CH"
    return
        $item
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
    let $head := ec:get-head($model?xml//tei:teiHeader//tei:msDesc)
    return
        app:show-if-exists($node, $head, function() {
            $pm-config:web-transform($head, map { "root": $head }, $config:odd)
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
            [matches(.//tei:seriesStmt/tei:idno[1], ($model?doc/*[not(name(.) = 'num')]/text(), '\d+') => string-join('-'))]
            [not(.//tei:seriesStmt/tei:idno = $model?doc/@xml:id/data(.))]
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
    let $lang := $config:lang-settings?lang
    return
        (<h3 xmlns:i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/module"><i18n:text key="partners">Projektpartner</i18n:text></h3>,
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
        <h3 xmlns:i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/module"><i18n:text key="funding">Finanzielle Unterstützung</i18n:text></h3>,
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

(: TODO: Bedarf der Anpassung an das neue Schema :)
declare
     %templates:wrap
function app:show-credits($node as node(), $model as map(*)) {
    let $partner := root($model?xml)//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:availability/tei:p[@xml:id="facs"]/text()
    return
        if ($partner) then
            <p xmlns:i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/module"><i18n:text key="credits"/>{' ' || $partner}</p>
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
        $pm-config:web-transform($data, map {
              "root": $data,
              "mode": $mode,
              "lang": $config:lang-settings?lang
            }, $config:odd)

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
function app:help($node as node(), $model as map(*)) {
    let $lang := $config:lang-settings?lang
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

(: ~
: Note: This function should be removed in the future
: it is just some glue code, for the templating module and
: which is used by the ssrq specific parse-params.
: Why should try to use the lib:parse-params (which is part of the new
: templating module) instead.
:)
declare %private function app:get-template-configuration($model as map(*), $func as xs:string) {
    if (not(map:contains($model, $templates:CONFIGURATION))) then
        error($templates:CONFIGURATION_ERROR, "Configuration map not found in model. Tried to call: " || $func)
    else
        $model($templates:CONFIGURATION)
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
                                        app:get-template-configuration($model, "templates:form-control")($templates:CONFIG_PARAM_RESOLVER)($paramName)
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

declare function app:highlight-active-lang($node as node(), $model as map(*)) {
     element { node-name($node) } {
            $node/@* except $node/@data-template,
            for $child in $node/*
            let $is-active :=
                ends-with($child/@href, $config:lang-settings?lang)
            return
                element {node-name($child)} {
                    $child/@*,
                    (attribute { 'class' } { 'selected-lang' })[$is-active],
                    $child/text()
                }
     }
};
