xquery version "3.1";

module namespace ssrq-utils="http://existsolutions.com/ssrq/utils";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";
import module namespace pmf="http://www.tei-c.org/tei-simple/xquery/functions/ssrq-common" at "ext-common.xql";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace i18n="http://exist-db.org/xquery/i18n";


declare variable $ssrq-utils:TEMP_DOCS := collection($config:temp-root)/tei:TEI;
declare variable $ssrq-utils:ALL_DOCS := collection($config:data-root);
declare variable $ssrq-utils:SPECIAL_DOCS := collection($config:data-root)/tei:TEI[@type];
declare variable $ssrq-utils:CANTONS := util:binary-doc($config:app-root || '/resources/json/cantons.json')  => util:binary-to-string() => parse-json();
declare variable $ssrq-utils:STATIC := $config:app-root || '/static';


(:~
: A simple utility function to load static generated content
:
: @param $page name of the page as xs:string
: @return static html content
:)
declare function ssrq-utils:loadStatic($node as node(), $model as map(*), $page as xs:string, $collection as xs:string?) as node()* {
    let $lang := (session:get-attribute("ssrq.lang"), "de")[1]
    let $path := $ssrq-utils:STATIC || '/' || $page || '_' || string-join(($collection, $lang), '_') || '.html'
    return doc($path)
};

(:~
: Utility function to find a view by url-params
:
: @param $collection selected canton
: @param $volume selected volume
: @return static html content
:)
declare function ssrq-utils:findView($node as node(), $model as map(*), $collection as xs:string?, $volume as xs:string?) as node()*  {
    let $view := if ($volume and $collection) then 'works' else 'volumes'
    return
        switch($view)
        case 'works' return <div>{
            let $works := ssrq-utils:listWorks($node, $model, $collection, $volume, ())
            return ssrq-utils:renderWork($node, $works)

            }</div>
        default return ssrq-utils:loadStatic($node, $model, $view, $collection)
};


(:~
: Utility function to sort multiple items (Unterstücke) of one article (Stück) by their tei:idno
:
: @author Bastian Politycki
: @param $items the article as item()*
: @return sorted list of items as item()*
:)
declare function ssrq-utils:sortArticle($items as item()*) as item()* {
    for $item in $items
    order by $item//tei:seriesStmt/tei:idno/text()
    return $item
};


(:~
: Utility function to filter a collection of documents by tei:idno
:
: @author Bastian Politycki
: @param $path the root path the collection
: @param $idno idno-schema of the collection
: @return filtered list as map(*)*
:)
declare function ssrq-utils:filterCollection($collection as item()*, $idno as xs:string) as map(*)* {
    let $docs := for $doc in $collection except(
                          $ssrq-utils:TEMP_DOCS union
                          $ssrq-utils:SPECIAL_DOCS
                        )
                group by $id := $doc//tei:seriesStmt[@xml:id = 'ssrq-sds-fds']/tei:idno => functx:get-matches($idno || '_[0-9]{0,4}_{0,1}')
                return
                    map {
                        "key": $id,
                        "doc": if($doc => count() > 1) then $doc => ssrq-utils:sortArticle() else $doc
                    }
    return $docs
};


declare
    %templates:wrap
function ssrq-utils:fixLinks($node as node(), $model as map(*)) {
    ssrq-utils:fixLinks(templates:process($node/node(), $model))
};

declare function ssrq-utils:fixLinks($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(a) | element(link) return
                (: skip links with @data-template attributes; otherwise we can run into duplicate @href errors :)
                if ($node/@data-template) then
                    $node
                else
                    let $href :=
                        replace(
                            $node/@href,
                            "\$app",
                            (request:get-context-path() || substring-after($config:app-root, "/db"))
                        )
                    return
                        element { node-name($node) } {
                            attribute href {$href}, $node/@* except $node/@href, ssrq-utils:fixLinks($node/node())
                        }
            case element() return
                element { node-name($node) } {
                    $node/@*, ssrq-utils:fixLinks($node/node())
                    
                }
            default return
                $node
};

(:~~
: Utility Function to insert an alt-Attribute into html:img
:
: @return $node as node()
:)
declare function ssrq-utils:insertAlt($node as node(), $model as map(*)) as node() {
    <img class="{$node/@class/data(.)}" src="{$node/@src/data(.)}" alt="{config:app-title($node, $model)}"/>
};


(:~
: Filter docs in a collection by their tei:idno and count them
:
: @author Bastian Politycki
: @param $path the root path the collection
: @param $idno idno-schema of the collection
: @return count as xs:string
:)
declare function ssrq-utils:countDocs($path as xs:string, $idno as xs:string) as xs:integer {
    let $docs := collection($path)/tei:TEI => ssrq-utils:filterCollection($idno)
    return $docs => count()
};


declare function ssrq-utils:sortCollection($items as map(*)*, $sortBy as xs:string?) {
    let $items := $items ! .?doc[1]
    return
    switch($sortBy)
        case "kanton" return
            for $item in $items
            order by replace(root($item)//tei:teiHeader//tei:seriesStmt/tei:idno, "^(?:SSRQ|SDS|FDS)_([^_]+).*$", "$1")
            return
               $item
        (:~
        case "title" return
            for $item in $items
            let $header := root($item)//tei:teiHeader
            order by
                ($header//tei:msDesc/tei:head/string(), $header//tei:titleStmt/tei:title/string())[1]
            return
                $item
        case "id" return
            for $item in $items
            order by root($item)//tei:teiHeader/tei:fileDesc/tei:seriesStmt/tei:idno
            return
                $item
        case "relevance" return
            for $item in $items
            order by ft:score($item)
            return
                $item ~:)
        default return
            for $item in $items
            order by root($item)//tei:teiHeader/tei:fileDesc/tei:seriesStmt/tei:idno
            return
               $item
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

(:~
: Render cantons listed in $ssrq-utils:CANTONS as html
:
: @author Bastian Politycki
: @return a html:div per canton and wrap it in a html:div
:)
declare function ssrq-utils:listCantons($node as node(), $model as map(*)) as node() {
    <tbody>
    {
    for $key in map:keys($ssrq-utils:CANTONS)
    order by $ssrq-utils:CANTONS($key)?order
    return
        if ($key => contains('-'))
        then ssrq-utils:renderMergedCantons($ssrq-utils:CANTONS($key))
        else ssrq-utils:renderCanton($key, $ssrq-utils:CANTONS($key))
    }
    </tbody>
};




declare function ssrq-utils:renderCanton($key as xs:string, $data as map(*)) as node() {
    <tr>
            <td><img src="{concat('resources/images/kantone/', $data?img, '.png')}"/></td>
            <td>{$key}</td>
        {ssrq-utils:renderDepartment($data,$key)}
    </tr>
};

declare function ssrq-utils:renderMergedCantons($data as map(*)) as node()* {
    let $keys :=  map:keys($data)
    return
    <tr>
        <td>
            {
                for $key in $keys[not(. = 'order')]
                return
                    <img src="{concat('resources/images/kantone/', $data($key)?img,  '.png')}"/>
            }
        </td>
        <td>
            {$keys[not(. = 'order')] => string-join('/')}
        </td>
        {ssrq-utils:renderDepartment($data($keys[1]),$keys[1])}
    </tr>
};

declare function ssrq-utils:renderDepartment($data as map(*), $dep as xs:string) as node()* {
    let $rootCollection := $config:data-root || '/' || $dep
    return
    if (xmldb:collection-available($rootCollection))
    then
        <td>
            <div class="canton--badge">
                <a href="?collection={$dep}" data-collection="{$dep}">
                    {
                    let $html := $data?department => util:parse-html()
                    return $html/*/*[last()]/node()
                    }
                </a>
                <span class="badge">{
                    try {
                        sum(let $childCollections := xmldb:get-child-collections($rootCollection)
                        for $collection in $childCollections
                        return ssrq-utils:countDocs($rootCollection || '/' || $collection, $collection))
                    } catch * {console:log('Problem while filtering ' || $dep), 'Error! ' || $dep}
                }</span>
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
: @param $collection canton as xs:string
: @return one html:div container per volume
:)
declare function ssrq-utils:listVolumes($node as node(), $model as map(*), $collection as xs:string) as node()* {
    <div class="volumes">
    {
    for $volume in collection($config:data-root)/tei:TEI[@type = 'volinfo'][matches(.//tei:seriesStmt/tei:idno[@type="machine"], '^\w+_' || $collection)]
        order by $volume//tei:seriesStmt/tei:idno[@type = 'sort']
        let $idno := $volume//tei:seriesStmt/tei:idno[@type="machine"]
        let $collection-name := util:collection-name($volume)
        let $volume-collection := collection($collection-name)
        let $context := request:get-context-path() || substring-after($config:app-root, "/db")
        let $content-types := map {
            "introduction": $volume-collection/tei:TEI[@type='introduction'][.//tei:seriesStmt/tei:idno = $idno],
            "archives": $volume-collection/tei:TEI[@type='archives'][.//tei:seriesStmt/tei:idno = $idno],
            "editions": $volume-collection/tei:TEI[@type='editions'][.//tei:seriesStmt/tei:idno = $idno],
            "literature":$volume-collection/tei:TEI[@type='biblio'][.//tei:seriesStmt/tei:idno = $idno],
            "bailiffs": $volume-collection/tei:TEI[@type='bailiffs'][.//tei:seriesStmt/tei:idno = $idno],
            "foreword": $volume-collection/tei:TEI[@type='foreword'][.//tei:seriesStmt/tei:idno = $idno],
            "preface": $volume-collection/tei:TEI[@type='preface'][.//tei:seriesStmt/tei:idno = $idno],
            "pdfdummy": $volume-collection/tei:TEI[@type='pdfdummy'][.//tei:seriesStmt/tei:idno = $idno]
        }
        return
            <div class="volume">
                <div class="volume-counter">
                    <span class="badge">
                        {ssrq-utils:countDocs($collection-name, $idno)}
                    </span>
                </div>
                {$pm-config:web-transform($volume/tei:teiHeader/tei:fileDesc, map { "root": $volume, "view": "volumes" }, $config:odd) }
                <span class="part">
                {
                    let $works-id := substring-after($collection-name, $collection || "/")
                    return
                    <a href="?collection={$collection}&amp;volume={$works-id}" data-works="{$works-id}" >
                        <i18n:text key="articles">Stücke</i18n:text>
                    </a>
                }
                </span>
                {
                   for $key in $content-types => map:keys()
                   return
                        if ($content-types($key))
                        then
                            <span class="part">
                                {
                                    let $path := substring-after(document-uri(root($content-types($key))), $config:data-root || "/")
                                    let $href := if ($key = 'pdfdummy') then request:get-context-path() || '/apps/ssrq-data/data/' || replace($path, '^([A-Z]{2})/(.+?)/(.+?)(?:_\d{1,2})?\.xml$', '$1/$2/pdf/' || $idno || '.pdf') else $path || '?template=introduction.html'
                                    return
                                        <a href="{$href}">
                                           <i18n:text key="{$key}">{$key}</i18n:text>
                                        </a>
                                }
                            </span>
                        else ()
                }
            </div>
    }</div>
};

(:~
: List works per volume
: Replaces app:list-works
:
: @param $collection selected canton
: @param volume selected volue
: @return a sorted list of documents inside a volume-collection as map(*)
:)
declare
    %templates:default("sort", "date")
function ssrq-utils:listWorks($node as node(), $model as map(*), $collection as xs:string, $volume as xs:string, $sort as xs:string?) as map(*)  {
    let $volume-collection := collection(string-join(($config:data-root, $collection, $volume), '/'))/tei:TEI
    (: TO-DO Implement a better function, which sorts the collection-map... :)
    let $volume-docs := ssrq-utils:filterCollection($volume-collection, $volume)
    let $volume-sorted := ssrq-utils:sortCollection($volume-docs, $sort)
    return
        map {
            "docs": $volume-sorted
        }
};

declare
function ssrq-utils:renderWork($node as node(), $model as map(*)) {
   for $doc in $model?docs
     let $config := tpu:parse-pi(root($doc), ())
     let $relPath := config:get-identifier($doc)
     let $root := $doc/ancestor-or-self::tei:TEI
    return
        <li class="document ml-1">
        {
            $pm-config:web-transform($root/tei:teiHeader, map {
                    "header": "short",
                    "doc": $relPath || "?odd=" || $config:odd || "&amp;view=" || $config?view,
                    "root": $root
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
    function ssrq-utils:loadWorks($node as node(), $model as map(*), $collection as xs:string, $volume as xs:string, $start as xs:int, $per-page as xs:int) as map(*) {
        let $lang := (session:get-attribute("ssrq.lang"), "de")[1]
        let $path := $ssrq-utils:STATIC || '/' || 'works' || '_' || string-join(($volume, $lang), '_') || '.html'
        let $documents := doc($path)//*[@class = 'document ml-1']
        return
            map {
                "total": count($documents),
                "page": subsequence($documents, $start, $per-page)
            }
};

(:~
: Display current works on selected page
:
: @return html:ul
:)
declare function ssrq-utils:browse($node as node(), $model as map(*)) as element(ul) {
        <ul class="documents">
            {$model?page}
        </ul>
};

(:~
: Helper-Function to construct a browse-up-link
:
: @return $node as node()
:)
declare function ssrq-utils:browseUp($node as node(), $model as map(*), $collection as xs:string) as node() {
    element { node-name($node) } {
        attribute href {'?collection=' || $collection},
        $node/node()
    }
};



declare function ssrq-utils:linkPagination($collection as xs:string, $volume as xs:string, $start) {
   let $link := '?collection=' || $collection || '&amp;volume=' || $volume || '&amp;start=' || $start
   return $link
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
function ssrq-utils:paginate($node as node(), $model as map(*), $key as xs:string, $start as xs:int, $per-page as xs:int, $min-hits as xs:int,
    $max-pages as xs:int, $collection as xs:string, $volume as xs:string) {
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
                        <a href="{ssrq-utils:linkPagination($collection, $volume, 1)}"><i class="glyphicon glyphicon-fast-backward"/></a>
                    </li>,
                    <li><a href="{ssrq-utils:linkPagination($collection, $volume, max( ($start - $per-page, 1 ) ))}"><i class="glyphicon glyphicon-backward"/>
                       </a></li>
                ),
                let $startPage := xs:integer(ceiling($start div $per-page))
                let $lowerBound := max(($startPage - ($max-pages idiv 2), 1))
                let $upperBound := min(($lowerBound + $max-pages - 1, $count))
                let $lowerBound := max(($upperBound - $max-pages + 1, 1))
                for $i in $lowerBound to $upperBound
                return
                    if ($i = ceiling($start div $per-page)) then
                        <li class="active"><a href="{ssrq-utils:linkPagination($collection, $volume, max( (($i - 1) * $per-page + 1, 1) ))}">{$i}</a></li>
                    else
                        let $page := max((($i - 1) * $per-page + 1, 1))
                        return
                        <li><a href="{ssrq-utils:linkPagination($collection, $volume, $page)}">{$i}</a></li>,
                if ($start + $per-page < $model($key)) then (
                    <li>
                        <a href="{ssrq-utils:linkPagination($collection, $volume,$start + $per-page)}"><i class="glyphicon glyphicon-forward"/></a>
                    </li>,
                    <li>
                        <a href="{ssrq-utils:linkPagination($collection, $volume, max( (($count - 1) * $per-page + 1, 1)))}"><i class="glyphicon glyphicon-fast-forward"/></a>
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
declare function ssrq-utils:hits($node as node(), $model as map(*), $collection as xs:string, $volume as xs:string) {
       <a href="?collection={$collection}&amp;volume={$volume}&amp;per-page={$model?total}">{$model?total}</a>
};


(:~
: Renndering functions used for ?template=introduction.html
:
:
:
:)
declare function ssrq-utils:renderHeadings($section as node(), $pos, $type as xs:string*) {
    let $section-heading := $section/tei:head
    return
    if ($section-heading/@type = 'title' or $section-heading/@type = 'subtitle')
    then
        let $subsections := $section => ssrq-utils:getSubsections()
        let $output :=
                if ($section-heading/*)
                (:~To_DO Rendering durch PM :)
                then ()
                else $section-heading/string()
        let $link := if ($type = 'introduction') then ('#section-' || $pos) else ('#' || pmf:heading-id($section-heading))
        return
            <li>
                <a href="{$link}" class="toc-anchor">{$output}</a>
                    {
                    if ($subsections and ($subsections//tei:head/@type = 'title' or $subsections//tei:head/@type = 'subtitle'))
                    then
                        <ul>
                            {
                            for $subsection at $subpos in $subsections
                            return
                            ssrq-utils:renderHeadings($subsection, $pos || '-' || $subpos, $type)
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
declare function ssrq-utils:printToc($node as node(), $model as map(*)) as node()* {
    if (not($model?doc-type = 'bailiffs'))
    then
        let $divs := $model?data => ssrq-utils:getSubsections()
        let $head := <h3><i18n:text key="toc"/></h3>
        return
            (templates:process($head, $model),
            <ul id="toc">
                {
                for $div at $pos in $divs
                let $html := ssrq-utils:renderHeadings($div, $pos, $model?doc-type)
                return
                    $html
                }
            </ul>)
    else ()
};


(:~
: Get subsection from an introduction text
:
: @return all tei:divs with tei:head as a direct child
:)
declare function ssrq-utils:getSubsections($root as node()) as node()* {
    $root//tei:div[tei:head] except $root//tei:div[tei:head]//tei:div
};
