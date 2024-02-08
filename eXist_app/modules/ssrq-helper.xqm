xquery version "3.1";

module namespace ssrq-helper="http://ssrq-sds-fds.ch/exist/apps/ssrq/helper";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xqm";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xqm";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace functx="http://www.functx.com";
import module namespace cache="http://exist-db.org/xquery/cache";
import module namespace session="http://exist-db.org/xquery/session";
import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "utils.xqm";
import module namespace app="http://ssrq-sds-fds.ch/exist/apps/ssrq/app" at "ssrq.xqm";
import module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common" at "ext-common.xqm";
import module namespace response="http://exist-db.org/xquery/response";
import module namespace ssrq-cache="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/cache" at "repository/cache.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/module";


declare variable $ssrq-helper:TEMP_DOCS := collection($config:temp-root)/tei:TEI;
declare variable $ssrq-helper:ALL_DOCS := collection($config:data-root);
declare variable $ssrq-helper:SPECIAL_DOCS := collection($config:data-root)/tei:TEI[@type];
declare variable $ssrq-helper:CANTONS := util:binary-doc($config:app-root || '/resources/json/cantons.json')  => util:binary-to-string() => parse-json();
declare variable $ssrq-helper:STATIC := $config:app-root || '/static';

(: DEPRECATED: template-utils:resolve-links :)
declare
function ssrq-helper:resolve-links($node as node(), $model as map(*)) {
    element { node-name($node) } {
        $node/@* except $node/@data-template,
        templates:process($node/node(), $model)
    } => ssrq-helper:resolve-links()
};

(: DEPRECATED: template-utils:resolve-links :)
declare function ssrq-helper:resolve-links($nodes as node()*) {
    let $proc-attribute := function ($input-value, $add-lang-param) {
        let $url :=
            (analyze-string($input-value, "\{[a-z-]+\}")/fn:match => distinct-values()) ! replace(., "^\{(.*)\}$", "$1")
            => fold-left($input-value, function ($s, $var) {
                    let $repl :=
                        switch ($var)
                        case 'app' return $config:base-url
                        case 'uri' return request:get-uri()
                        case 'qs' return "" || request:get-query-string()
                        default return
                            request:get-parameter($var, concat("{", $var, "}"))
                    return
                        replace($s, concat("\{", $var, "\}"), xs:string($repl))
            })
        let $path :=
            if ($url => contains("?")) then
                $url => substring-before("?")
            else
                $url
        let $query-map :=
            (($url => substring-after("?") => tokenize("[&amp;;]")) ! (
                if (. = "") then
                    ()
                else if (. => contains("=")) then
                    map{substring-before(., "="): substring-after(., "=")}
                else
                    map{.:()}
            )) => map:merge()
        return
            ec:create-link(
                $path, $query-map,
                $add-lang-param and $input-value => starts-with("{app}"))
    }
    for $node in $nodes
    return
        typeswitch($node)
            case element(a) | element(link) return
                if ($node/@href) then
                    element { node-name($node) } {
                        attribute href {
                            if ($node/@href => matches("^(?:[a-z-]+:)|#")) then
                                (: not a URL :)
                                $node/@href
                            else
                                $proc-attribute(
                                    $node/@href,
                                    node-name($node) = xs:QName("a"))
                        },
                        $node/@* except $node/@href,
                        ssrq-helper:resolve-links($node/node())
                    }
                else
                    element { node-name($node) } {
                        $node/@*,
                        ssrq-helper:resolve-links($node/node())
                    }
            case element(form) return
                if ($node/@action) then
                    element { node-name($node) } {
                        attribute action { $proc-attribute($node/@action, true()) },
                        $node/@* except $node/@action,
                        ssrq-helper:resolve-links($node/node())
                    }
                else
                    element { node-name($node) } {
                        $node/@*,
                        ssrq-helper:resolve-links($node/node())
                    }
            case element(script) | element(img) return
                if ($node/@src) then
                    element { node-name($node) } {
                        attribute src { $proc-attribute($node/@src, false()) },
                        $node/@* except $node/@src
                    }
                else
                    element { node-name($node) } {
                        $node/@*,
                        ssrq-helper:resolve-links($node/node())
                    }
            case element() return
                element { node-name($node) } {
                    $node/@*,
                    ssrq-helper:resolve-links($node/node())
                }
            default return
                $node
};




(:~
:
:
:
:  ***FUNCTIONS USED FOR RENDERING / USED INSIDE @data-template***
:
:
:
:
:)



(: ~
: Templating function to load documents from the /temp collection
:
: @author: Bastian Politycki
: @date: 2022.08.02
: @return a map, which holds the actual tei xml-file and some additional config-infos
:
:)
declare
function ssrq-helper:get-temp($node as node(), $model as map(*), $file as xs:string, $view as xs:string?, $odd as xs:string?) as map(*) {
    let $path := utils:path-concat(($config:temp-root, $file))
    return
        if (doc-available($path)) then
            let $xml := doc($path)/tei:TEI

            let $has-facs := exists($xml//tei:pb[@facs]) and not($odd eq $config:odd-normalized)
            return
                map {
                    "idno": $xml//tei:seriesStmt//tei:idno,
                    "filename": $file,
                    "show-download": false(),
                    "xml": $xml,
                    "config": map {
                        "odd": utils:coalesce($odd, $config:odd),
                        "view": app:query-view($xml/tei:text, utils:coalesce($view, $config:default-view))
                    },
                    "body-class": if ($has-facs) then 'col-md-6' else 'col-md-10',
                    "has-facs": xs:string($has-facs)
                }
        else
            error(xs:QName('ssrq:helper'), 'No unique result found for ' || $file)

};


declare
function ssrq-helper:xml-to-tex($node as node(), $model as map(*))  {
    try {
        string-join(
            $pm-config:latex-transform($model?xml, (), $config:odd)
        )
    } catch * {
        error(xs:QName('ssrq-helper:xml-to-tex'), 'Error while converting xml to TeX: ' || $err:description)
    }
};


declare function ssrq-helper:pers-names($header as node()*) {
let $namen :=  $header//tei:persName/text()
return
    if (count($namen) > 1) then (
        string-join(subsequence($namen, 1, count($namen) -1), ', '),
        <i18n:text xmlns:i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/module" key="and"> und </i18n:text>,
        $namen[last()]
    ) else
        $namen
};

declare
%templates:wrap
function ssrq-helper:render-idno-as-popup($node as node(), $model as map(*), $idno-link) as element(span)? {
    let $header := $model?xml//tei:teiHeader/tei:fileDesc
    let $stmtTitle := $header/tei:seriesStmt/tei:title/text()
    let $fileDescTitle := $header/tei:titleStmt/tei:title
    let $idno_infos := ssrq-helper:get-idno-infos($model?doc)
    return
        <span class="alternate">
            <span class="id" data-idno="{$idno_infos[2]}">{$idno_infos[1]} <i class="glyphicon glyphicon-info-sign"/></span>
            <span class="altcontent" xmlns:i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/module" popover-class="increase-popover-width">
                    <p>{$stmtTitle}, {$pm-config:web-transform($fileDescTitle, map { "root": $fileDescTitle, "view": "infopopup"}, $config:odd)}, <i18n:text key="by">von</i18n:text> {ssrq-helper:pers-names($header//tei:editor)}</p>
                    <p><i18n:text key="zitation">Zitation:</i18n:text>
                    { if ($idno-link => empty() or xs:boolean($idno-link)) then
                        <a href="{ec:create-p-link-from-id($idno_infos[2])}">{$idno_infos[1]}</a>
                      else
                        $idno_infos[1]
                    }
                    </p>
                    <p><i18n:text key="lizenz">Lizenz:</i18n:text> <a href="https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode.de">CC BY-NC-SA</a></p>
            </span>
        </span>
};

declare function ssrq-helper:get-idno-infos($idno as element()) as xs:string+ {
     typeswitch($idno)
            case element(doc) return
                (ec:print-id($idno), $idno/@xml:id)
            default return
                ($idno/string(), $idno/string())
};

declare
function ssrq-helper:render-work($node as node(), $model as map(*), $kanton as xs:string?, $volume as xs:string?) as element(li)* {
    for $doc in $model?current-page-documents
    let $xml := collection($config:data-root)/tei:TEI[.//tei:idno eq $doc/@xml:id/data(.)]
    return
        <li class="document ml-1">
        {
            $pm-config:web-transform($xml//tei:teiHeader, map {
                    "header": "short",
                    "doc": ec:create-app-link(($kanton, $volume, (string-join(($doc/case, $doc/doc), '.'), $doc/num) => string-join('-') || '.html')),
                    "root": $xml
                }, $config:odd)
        }
        </li>
};


(:~
: Load a subsequence of works stored in /static and pass them to the $model
:
: @return $model as map(*)
:)
declare
%templates:wrap
%templates:default("start", 1)
%templates:default("per-page", 10)
%templates:default("sort", "date")
    function ssrq-helper:load-works($node as node(), $model as map(*), $kanton as xs:string, $volume as xs:string, $start as xs:int, $per-page as xs:int, $sort as xs:string?) as map(*) {
        let $volume-docs := ssrq-cache:load-from-static-cache-by-id($config:static-cache-path, $config:static-docs-list, ($kanton,$volume) => string-join('-'))
        let $grouped-docs := $volume-docs/doc[not(special)][not(opening)][not(case)][num eq '1']
                            union $volume-docs/doc[not(special)][not(opening)][case][doc eq '0'][num eq '1']
        return
            map {
                "total": count($grouped-docs),
                "page": $grouped-docs => subsequence($start, $per-page)
            }
};


(:~
 : Inserts the current language into a node's attribute
 :
 : @param $attr the name of the attribute in which to put the language code
 : @param $always always set the language, not only if it needs to be carried in
 :        the URL
 :)
declare function ssrq-helper:insert-lang($node as node(), $model as map(*),
                                         $attr, $always) as node()? {
    if (xs:boolean($always) or $config:lang-settings?add-lang-param) then
        element { node-name($node) } {
            $node/@* except ($node/@data-template, $node/@data-template-attr, $node/@data-template-always),
            attribute { $attr } { $config:lang-settings?lang },
            templates:process($node/node(), $model)
        }
    else
        ()
};


(:TODO -> Build a generic pagination solution, which can also be used by the search! :)
(:~
: Builds an bootstrap-based-pagination bar
:
: @param $key the default key to look up the total value in the $model
: @param $start starting page
:)
declare
    %templates:default('key', 'total')
    %templates:default('start', 1)
    %templates:default("per-page", 10)
    %templates:default("min-hits", 0)
    %templates:default("max-pages", 10)
function ssrq-helper:paginate($node as node(), $model as map(*), $key as xs:string, $start as xs:int, $per-page as xs:int, $min-hits as xs:int,
    $max-pages as xs:int, $kanton as xs:string, $volume as xs:string) {
    if (($min-hits < 0 or $model($key) >= $min-hits) and $model($key) != $per-page) then
        element { node-name($node) } {
            $node/@*,
            let $count := xs:integer(ceiling($model($key)) div $per-page) + (if (xs:integer(ceiling($model($key)) mod $per-page) > 0) then 1 else 0)
            let $middle := ($max-pages + 1) idiv 2
            return (
                if ($start = 1) then (
                    <li class="disabled">
                        <a><i class="glyphicon glyphicon-fast-backward"/></a>
                    </li>,
                    <li class="disabled">
                        <a><i class="glyphicon glyphicon-backward"/></a>
                    </li>
                ) else (
                    <li>
                        <a href="{ec:create-app-link(($kanton, $volume, ''), map{'start': 1})}"><i class="glyphicon glyphicon-fast-backward"/></a>
                    </li>,
                    <li><a href="{ec:create-app-link(($kanton, $volume, ''), map{'start': max(($start - $per-page, 1))})}"><i class="glyphicon glyphicon-backward"/>
                       </a></li>
                ),
                let $startPage := xs:integer(ceiling($start div $per-page))
                let $lowerBound := max(($startPage - ($max-pages idiv 2), 1))
                let $upperBound := min(($lowerBound + $max-pages - 1, $count))
                let $lowerBound := max(($upperBound - $max-pages + 1, 1))
                for $i in $lowerBound to $upperBound
                return
                    if ($i = ceiling($start div $per-page)) then
                        <li class="active"><a href="{ec:create-app-link(($kanton, $volume, ''), map{'start': max((($i - 1) * $per-page + 1, 1))})}">{$i}</a></li>
                    else
                        let $page := max((($i - 1) * $per-page + 1, 1))
                        return
                        <li><a href="{ec:create-app-link(($kanton, $volume, ''), map{'start': $page})}">{$i}</a></li>,
                if ($start + $per-page < $model($key)) then (
                    <li>
                        <a href="{ec:create-app-link(($kanton, $volume, ''), map{'start': ($start + $per-page)})}"><i class="glyphicon glyphicon-forward"/></a>
                    </li>,
                    <li>
                        <a href="{ec:create-app-link(($kanton, $volume, ''), map{'start': max((($count - 1) * $per-page + 1, 1))})}"><i class="glyphicon glyphicon-fast-forward"/></a>
                    </li>
                ) else (
                    <li class="disabled">
                        <a><i class="glyphicon glyphicon-forward"/></a>
                    </li>,
                    <li>
                        <a><i class="glyphicon glyphicon-fast-forward"/></a>
                    </li>
                )
            )
        }
    else
        ()
};


(:~
: Build a simple counter and enable function to show all hits
:
: @param $collection the current canton
: @param $volume the current volume inside a canton
: @return total count inside a html:a
:)
declare function ssrq-helper:hits($node as node(), $model as map(*), $kanton as xs:string, $volume as xs:string) {
   <a href="{ec:create-app-link(($kanton, $volume, ''), map{'per-page': $model?total})}">{$model?total}</a>
};


(:~
: Rendering functions used for ?template=introduction.html
:)
declare function ssrq-helper:renderHeadings($section as node()) as element(li)* {
    let $section-heading := $section => ec:get-head()
    let $session-lang := $config:lang-settings?lang
    let $lang := if (not($section/ancestor::tei:div[@type = 'section'][tei:div[@xml:lang = $session-lang]])) then 'de' else $session-lang
    return
    if (
        $section-heading/@type = 'title' or $section-heading/@type = 'subtitle'
    )
    then
        let $subsections := $section => ssrq-helper:getSubsections()
        let $output := ($section-heading/@n, $section-heading/text()) => string-join(' ')
        return
            <li>
                <a href="#{util:node-id($section-heading)}" class="toc-anchor">{$output}</a>
                    {
                    if ($subsections and ($subsections//tei:head/@type = 'title' or $subsections//tei:head/@type = 'subtitle'))
                    then
                        <ul>
                            {
                            for $subsection in $subsections
                            return
                                ssrq-helper:renderHeadings($subsection)
                            }
                        </ul>
                    else ()
                    }
            </li>[not($section/@xml:lang) or $section/@xml:lang = $lang and $section/ancestor::tei:div[@type = 'section'][tei:div[@xml:lang = $lang]]]
    else ()
};

(:~
: Print a TOC on introduction page
:
: @return TOC as html:ul
:)
declare function ssrq-helper:printToc($node as node(), $model as map(*)) as node()* {
    let $divs := $model?xml => ssrq-helper:getSubsections()
    let $head := <h3><i18n:text key="toc"/></h3>
    return
        (templates:process($head, $model),
        <ul id="toc">
            {
            for $div in $divs
            let $html := ssrq-helper:renderHeadings($div)
            return
                $html
            }
        </ul>)
};


(:~
: Get subsection from an introduction text
:
: @return all tei:divs with tei:head as a direct child
:)
declare function ssrq-helper:getSubsections($root as node()) as node()* {
    $root//tei:div[tei:head] except $root//tei:div[tei:head]//tei:div
};
