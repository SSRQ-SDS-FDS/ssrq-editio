xquery version "3.1";

module namespace ssrq-utils="http://existsolutions.com/ssrq/utils";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";
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
                        "doc": $doc
                    }
    return $docs
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
: @return a html:div per canton
:)
declare function ssrq-utils:listCantons($node as node(), $model as map(*)) as node()* {
    for $key in map:keys($ssrq-utils:CANTONS)
    order by $ssrq-utils:CANTONS($key)?order
    return
        if ($key => contains('-'))
        then ssrq-utils:renderMergedCantons($ssrq-utils:CANTONS($key))
        else ssrq-utils:renderCanton($key, $ssrq-utils:CANTONS($key))
};




declare function ssrq-utils:renderCanton($key as xs:string, $data as map(*)) as node() {
    <div class="canton">
        <div class="canton__name">
            <img src="{concat('resources/images/kantone/', $data?img, '.png')}"/>
            <span>{$key}</span>
        </div>
        {ssrq-utils:renderDepartment($data,$key)}
    </div>
};

declare function ssrq-utils:renderMergedCantons($data as map(*)) as node()* {
    let $keys :=  map:keys($data)
    return
    <div class="canton">
        <div class="canton__name--container">
            {
               for $key in $keys[not(. = 'order')]
                return
                    <div class="canton__name">
                        <img src="{concat('resources/images/kantone/', $data($key)?img,  '.png')}"/>
                        <span>{$key}</span>
                    </div>
            }
        </div>
        {ssrq-utils:renderDepartment($data($keys[1]),$keys[1])}
    </div>
};

declare function ssrq-utils:renderDepartment($data as map(*), $dep as xs:string) as node()* {
    let $rootCollection := $config:data-root || '/' || $dep
    return
    if (xmldb:collection-available($rootCollection))
    then
        (<div class="canton__department">
            <a href="?collection={$dep}" data-collection="{$dep}">
                {
                let $html := $data?department => util:parse-html()
                return $html/*/*[last()]/node()
                }
            </a>
        </div>,
        <div class="canton__badge">
            <span class="badge">{
                sum(let $childCollections := xmldb:get-child-collections($rootCollection)
                for $collection in $childCollections
                return ssrq-utils:countDocs($rootCollection || '/' || $collection, $collection))
            }</span>
        </div>)
    else
        <div class="canton__department">
            <p>{
                let $html := $data?department => util:parse-html()
                return $html/*/*[last()]/node()
            }</p>
        </div>
};


(:~
: List volumes per canton
:
: @param $collection canton as xs:string
: @return one html:div container per volume
:)
declare function ssrq-utils:listVolumes($node as node(), $model as map(*), $collection as xs:string) as node()* {
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
                                    let $href := if ($key = 'pdfdummy') then request:get-context-path() || '/apps/ssrq-data/data/$resource' || replace($path, '^([A-Z]{2})/(.+?)/(.+?)(?:_\d{1,2})?\.xml$', '$1/$2/pdf/' || $idno || '.pdf') else $path || '?template=introduction.html'
                                    return
                                        <a href="{$href}">
                                           <i18n:text key="{$key}">{$key}</i18n:text>
                                        </a>
                                }
                            </span>
                        else ()
                }
            </div>
};

(:
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
        <li class="document">
        {
            $pm-config:web-transform($root/tei:teiHeader, map {
                    "header": "short",
                    "doc": $relPath || "?odd=" || $config:odd || "&amp;view=" || $config?view,
                    "root": $root
                }, $config:odd)
        }
        </li>
};

declare
%templates:wrap
%templates:default("start", 1)
%templates:default("per-page", 10)
    function ssrq-utils:loadWorks($node as node(), $model as map(*), $collection as xs:string, $volume as xs:string, $start as xs:int, $per-page as xs:int) {
        let $lang := (session:get-attribute("ssrq.lang"), "de")[1]
        let $path := $ssrq-utils:STATIC || '/' || 'works' || '_' || string-join(($volume, $lang), '_') || '.html'
        let $documents := doc($path)//*[@class = 'document']
        return
            map {
                "total": count($documents),
                "page": subsequence($documents, $start, $per-page)
            }
};

declare function ssrq-utils:browse($node as node(), $model as map(*)) {
        <ul class="documents">
            {$model?page}
        </ul>
};

declare function ssrq-utils:browseUp($node as node(), $model as map(*), $collection as xs:string) {
    element { node-name($node) } {
        attribute href {'?collection=' || $collection},
        $node/node()
    }
};
