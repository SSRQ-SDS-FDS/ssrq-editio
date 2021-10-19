xquery version "3.1";

module namespace ssrq-utils="http://existsolutions.com/ssrq/utils";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xql";
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

declare function ssrq-utils:findView($node as node(), $model as map(*), $collection as xs:string?, $volume as xs:string?) {
    let $view := if ($volume and $collection) then 'works' else 'volumes'
    return
        ssrq-utils:loadStatic($node, $model, $view, $collection)
};




(:~
: Filter docs in a collection by their tei:idno and count them
:
: @author Bastian
: @param $path the root path the collection
: @param $idno idno-schema of the collection
: @return count as xs:string
:)


declare function ssrq-utils:countDocs($path as xs:string, $idno as xs:string) as xs:integer {
    let $docs := for $doc in collection($path)/tei:TEI except(
                          $ssrq-utils:TEMP_DOCS union
                          $ssrq-utils:SPECIAL_DOCS
                        )
               let $id := $doc//tei:seriesStmt[@xml:id = 'ssrq-sds-fds']/tei:idno => functx:get-matches($idno || '_[0-9]{0,4}_{0,1}')
                        group by $id
                        return $id
    return $docs => count()
};

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
                    <a href="{$context}?collection={$collection}&amp;volume={substring-after($collection-name, $config:data-root || "/")}" >
                        <i18n:text key="articles">Stücke</i18n:text>
                    </a>
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
