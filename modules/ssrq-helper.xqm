xquery version "3.1";

module namespace ssrq-helper="http://ssrq-sds-fds.ch/exist/apps/ssrq/helper";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xqm";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xqm";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace functx="http://www.functx.com";
import module namespace cache="http://exist-db.org/xquery/cache";
import module namespace session="http://exist-db.org/xquery/session";
import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "utils.xqm";
import module namespace config-data="http://ssrq-sds-fds.ch/exist/apps/ssrq-data/config" at "/db/apps/ssrq-data/modules/config.xqm";
import module namespace doc-list="http://ssrq-sds-fds.ch/exist/apps/ssrq-data/doc-list" at "/db/apps/ssrq-data/modules/doc-list.xqm";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace i18n="http://exist-db.org/xquery/i18n";


declare variable $ssrq-helper:TEMP_DOCS := collection($config:temp-root)/tei:TEI;
declare variable $ssrq-helper:ALL_DOCS := collection($config:data-root);
declare variable $ssrq-helper:SPECIAL_DOCS := collection($config:data-root)/tei:TEI[@type];
declare variable $ssrq-helper:CANTONS := util:binary-doc($config:app-root || '/resources/json/cantons.json')  => util:binary-to-string() => parse-json();
declare variable $ssrq-helper:STATIC := $config:app-root || '/static';
declare variable $ssrq-helper:ENV := doc($config:app-root || '/env.xml');


(:~
: This function is called by the eXist templating engine and
: will cache the inner content of a $node if caching is enabled in env.xml.
:
: @return the rendered (cached or compiled) result as node()
:)
declare function ssrq-helper:cache-store-retrieve($node as node(), $model as map(*), $prefix as xs:string?) as node() {
    let $use-cache := xs:boolean($ssrq-helper:ENV//cache/text())
    let $cache-key := ssrq-helper:make-cache-key($prefix)
    let $cached-content :=
        if ($use-cache) then
            cache:get($config-data:CACHE, $cache-key)
        else
            ()
    return
        if (not(empty($cached-content))) then
            $cached-content
        else
            let $output := templates:process($node/*, $model)
            (: Put things in cache, but return $output, becacuse cache:put returns an empty sequence altough $output is not empty... :)
            let $put := if ($use-cache) then cache:put($config-data:CACHE, $cache-key, $output) else ()
            return
                $output
};

(: A small helper function to generate a mostly unique key by the request-parameter-names :)
declare function ssrq-helper:make-cache-key($prefix as xs:string) as xs:string {
    let $context := request:get-url() => substring-after('apps') => replace('/', '')
    let $params := request:get-parameter-names()[not(. = 'lang') and not(. = 'doc')] ! request:get-parameter(., ())
    let $lang := utils:coalesce(request:get-parameter('lang', ()), (session:get-attribute("ssrq.lang"), "de")[1])
    return
        ($prefix, $context, $params, $lang) => string-join('_')

};

declare function ssrq-helper:include-upload-template($node as node(), $model as map(*)) as element(div)? {
    if (xs:boolean($ssrq-helper:ENV//upload/text())) then
    doc(utils:path-concat-safe(($config:app-root, 'templates', 'upload.html')))
    else ()
};


(:~
: Helper function to create links based on the session attribute ssrq.prefix
: which is set by the controller – the function can be used as by other xquery-functions
: or directly from within the templates.
:
: @author Bastian Politycki
: @return xs:string
:)
declare function ssrq-helper:create-link($components as xs:string*, $params as map(*)*) as xs:string {
    let $query-params := (
                            for $param at $i in $params
                            return
                                string-join((if ($i eq 1) then '?' else '&amp;', $param?name, '=', $param?value), '')
    )[exists($params)]
    return
        utils:path-concat((session:get-attribute('ssrq.prefix'), $components, $query-params))
};

declare
%templates:wrap
function ssrq-helper:resolve-links($node as node(), $model as map(*)) {
    ssrq-helper:resolve-links(templates:process($node/node(), $model))
};

declare function ssrq-helper:resolve-links($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(a) | element(link) return
                (: skip links with @data-template attributes; otherwise we can run into duplicate @href errors :)
                if ($node/@data-template) then
                    $node
                else
                    let $href := ssrq-helper:create-link(
                                                            utils:path-tokenize($node/@href) ! (if (not(. eq '{app}')) then replace(., '\{([a-z]*)\}', '$1') => request:get-parameter(()) else ()),
                                                            ()
                                                        )
                    return
                        element { node-name($node) } {
                            attribute href {$href}, $node/@* except $node/@href, ssrq-helper:resolve-links($node/node())
                        }
            case element() return
                element { node-name($node) } {
                    $node/@*, ssrq-helper:resolve-links($node/node())
                }
            default return
                $node
};


(:~~
: Utility Function to insert an alt-Attribute into html:img
:
: @return $node as node()
:)
declare function ssrq-helper:insertAlt($node as node(), $model as map(*)) as node() {
    <img class="{$node/@class/data(.)}" src="{$node/@src/data(.)}" alt="{config:app-title($node, $model)}"/>
};


(:~
: Counter function used to display values inside the counter-‚bubbles‘
:
: @param $volume a volume element from docs.xml
: @return result as xs:integer
:)
declare
function ssrq-helper:count-docs($volume as element(volume)) as xs:integer {
    let $distinct-docs := for $doc in $volume/doc[not(special)]
                            group by $grouping-key := if ($doc/case) then $doc/case else $doc/doc
                            return $grouping-key
    return count($distinct-docs)

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

declare
function ssrq-helper:cantonslist-container($node as node(), $model as map(*)) {
    let $style :=
        element style {
            attribute type { "text/css" },
            text {
                (
                    "",
                    ".canton-img { display: inline-block; margin: 0 .375rem; }",
                    util:binary-doc("/db/apps/ssrq/resources/images/kantone/sprite.css")
                    => util:binary-to-string()
                    => replace("url\(sprite\.png\)", "url(resources/images/kantone/sprite.png)") (: FIXME: no hard-coded paths :)
                ) => string-join("&#10;")
            }
        }
    return
        element { node-name($node) } {
            $node/@*,
            $style,
            templates:process($node/node(), $model)
        }
};

(:~
: Render cantons listed in $ssrq-helper:CANTONS as html
:
: @author Bastian Politycki
: @return a html:div per canton and wrap it in a html:div
:)
declare function ssrq-helper:listCantons($node as node(), $model as map(*)) as node() {
    <tbody>
    {
    for $key in map:keys($ssrq-helper:CANTONS)
    order by $ssrq-helper:CANTONS($key)?order
    return
        if ($key => contains('-'))
        then ssrq-helper:renderMergedCantons($ssrq-helper:CANTONS($key))
        else ssrq-helper:renderCanton($key, $ssrq-helper:CANTONS($key))
    }
    </tbody>
};

declare function ssrq-helper:renderCanton($key as xs:string, $data as map(*)) as node() {
    <tr>
            <td><div class="canton-img {concat('canton-', $data?img)}"></div></td>
            <td>{$key}</td>
        {ssrq-helper:renderDepartment($data,$key)}
    </tr>
};

declare function ssrq-helper:renderMergedCantons($data as map(*)) as node()* {
    let $keys :=  map:keys($data)
    return
    <tr>
        <td>
            {
                for $key in $keys[not(. = 'order')]
                return
                    <div class="canton-img {concat('canton-', $data($key)?img)}"></div>
            }
        </td>
        <td>
            {$keys[not(. = 'order')] => string-join('/')}
        </td>
        {ssrq-helper:renderDepartment($data($keys[1]),$keys[1])}
    </tr>
};

declare function ssrq-helper:renderDepartment($data as map(*), $dep as xs:string) as node()* {
    let $rootCollection := $config:data-root || '/' || $dep
    return
    if (xmldb:collection-available($rootCollection))
    then
        <td>
            <div>
                <a href="{ssrq-helper:create-link($dep, ())}">
                    {
                    let $html := $data?department => util:parse-html()
                    return $html/*/*[last()]/node()
                    }
                </a>
                <span class="badge">{sum(doc-list:get($dep)/volume ! ssrq-helper:count-docs(.))}</span>
            </div>
        </td>
    else
        <td>
            {
                let $html := $data?department => util:parse-html()
                return $html/*/*[last()]/node()
            }
        </td>
};


(:~
: List volumes per canton
:
: @param $kanton canton as xs:string
: @return html:div which contains a html:div per volume
:)
declare function ssrq-helper:list-volumes($node as node(), $model as map(*), $kanton as xs:string) as element(div) {
    <div class="volumes">
        {
            for $volume in doc-list:get($kanton)/volume
            let $matching-doc := collection($config:data-root)/tei:TEI[.//tei:seriesStmt/tei:idno = $volume/doc[1]/@xml:id/data(.)]
            let $content-types := (
                                    map {"intro": $volume/doc[./special = 'intro' ]}, map{"bailiffs": $volume/doc[./special = 'bailiffs' ]},
                                    map{"lit": $volume/doc[./special = 'lit' ]}, map{"pdf": true()[xs:boolean($volume/@pdf)]}
                                  )
            return
                <div class="volume">
                    <div class="volume-counter">
                        <span class="badge">
                            {ssrq-helper:count-docs($volume)}
                        </span>
                    </div>
                    {
                        $pm-config:web-transform($matching-doc//tei:fileDesc, map { "root": $matching-doc, "view": "volumes" }, $config:odd),
                        <a class="part" href="{ssrq-helper:create-link(($kanton, $volume/@xml:id => substring(4)), ())}">
                            <i18n:text key="articles">Stücke</i18n:text>
                        </a>,
                        for $content-type in $content-types[exists(.?*)]
                        let $key := $content-type => map:keys()
                        return
                            <a class="part" href="{ssrq-helper:create-link(($kanton, $volume/doc[1]/volume, $key), ())}">
                                <i18n:text key="{$key}">{$key}</i18n:text>
                            </a>

                    }
                </div>
        }
    </div>
};


declare
function ssrq-helper:render-work($node as node(), $model as map(*), $kanton as xs:string?, $volume as xs:string?) as element(li)* {
    for $doc in $model?page
    let $xml := collection($config:data-root)/tei:TEI[.//tei:idno eq $doc/@xml:id/data(.)]
    return
        <li class="document ml-1">
        {
            $pm-config:web-transform($xml//tei:teiHeader, map {
                    "header": "short",
                    "doc": ssrq-helper:create-link(($kanton, $volume, ($doc/case, $doc/doc, $doc/num) => string-join('-') || '.html'), ()),
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
        let $volume-docs := doc-list:get(($kanton,$volume) => string-join('-'))
        let $grouped-docs := $volume-docs/doc[not(special)][not(opening)][not(case)][num eq '1']
                            union $volume-docs/doc[not(special)][not(opening)][case][doc eq '1'][num eq '1']
        return
            map {
                "total": count($grouped-docs),
                "page": $grouped-docs => subsequence($start, $per-page)
            }
};

(:~
: Display current works on selected page
:
: @return html:ul
:)
declare function ssrq-helper:browse($node as node(), $model as map(*)) as element(ul) {
        <ul class="documents">
            {$model?page}
        </ul>
};

(:~
: Helper-Function to construct a browse-up-link
:
: @return $node as node()
:)
declare function ssrq-helper:browseUp($node as node(), $model as map(*), $kanton as xs:string) as node() {
    element { node-name($node) } {
        attribute href {'?kanton=' || $kanton},
        $node/node()
    }
};

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
            let $count := xs:integer(ceiling($model($key)) div $per-page) + 1
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
                        <a href="{ssrq-helper:create-link(($kanton, $volume), map{'name': 'start', 'value': 1})}"><i class="glyphicon glyphicon-fast-backward"/></a>
                    </li>,
                    <li><a href="{ssrq-helper:create-link(($kanton, $volume), map{'name': 'start', 'value': max(($start - $per-page, 1 ))})}"><i class="glyphicon glyphicon-backward"/>
                       </a></li>
                ),
                let $startPage := xs:integer(ceiling($start div $per-page))
                let $lowerBound := max(($startPage - ($max-pages idiv 2), 1))
                let $upperBound := min(($lowerBound + $max-pages - 1, $count))
                let $lowerBound := max(($upperBound - $max-pages + 1, 1))
                for $i in $lowerBound to $upperBound
                return
                    if ($i = ceiling($start div $per-page)) then
                        <li class="active"><a href="{ssrq-helper:create-link(($kanton, $volume), map{'name': 'start', 'value':  max( (($i - 1) * $per-page + 1, 1) )})}">{$i}</a></li>
                    else
                        let $page := max((($i - 1) * $per-page + 1, 1))
                        return
                        <li><a href="{ssrq-helper:create-link(($kanton, $volume), map{'name': 'start', 'value': $page})}">{$i}</a></li>,
                if ($start + $per-page < $model($key)) then (
                    <li>
                        <a href="{ssrq-helper:create-link(($kanton, $volume),map{'name': 'start', 'value': $start + $per-page})}"><i class="glyphicon glyphicon-forward"/></a>
                    </li>,
                    <li>
                        <a href="{ssrq-helper:create-link(($kanton, $volume), map{'name': 'start', 'value': max( (($count - 1) * $per-page + 1, 1))})}"><i class="glyphicon glyphicon-fast-forward"/></a>
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
       <a href="?kanton={$kanton}&amp;volume={$volume}&amp;per-page={$model?total}">{$model?total}</a>
};


(:~
: Renndering functions used for ?template=introduction.html
:
:
:
:)
declare function ssrq-helper:renderHeadings($section as node()) as element(li)* {
    let $section-heading := $section/tei:head
    return
    if ($section-heading/@type = 'title' or $section-heading/@type = 'subtitle')
    then
        let $subsections := $section => ssrq-helper:getSubsections()
        let $output := $section-heading/text()
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
            </li>
    else ()
};

(:~
: Print a TOC on introduction page
:
: @return TOC as html:ul
:)
declare function ssrq-helper:printToc($node as node(), $model as map(*)) as node()* {
    let $divs := $model?data => ssrq-helper:getSubsections()
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
