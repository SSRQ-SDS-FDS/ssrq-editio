xquery version "3.1";

module namespace ssrq-utils="http://existsolutions.com/ssrq/utils";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace util="http://exist-db.org/xquery/util";


declare variable $ssrq-utils:TEMP_DOCS := collection($config:temp-root)/tei:TEI;
declare variable $ssrq-utils:ALL_DOCS := collection($config:data-root);
declare variable $ssrq-utils:SPECIAL_DOCS := collection($config:data-root)/tei:TEI[@type];
declare variable $ssrq-utils:CANTONS := util:binary-doc($config:app-root || '/resources/json/cantons.json')  => util:binary-to-string() => parse-json();

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
            <a href="#" data-collection="{$dep}">
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

declare function ssrq-utils:countDocs($path as xs:string, $idno as xs:string) as item() {
    let $docs := for $doc in collection($path)/tei:TEI except(
                          $ssrq-utils:TEMP_DOCS union
                          $ssrq-utils:SPECIAL_DOCS
                        )
               let $id := $doc//tei:seriesStmt[@xml:id = 'ssrq-sds-fds']/tei:idno => functx:get-matches($idno || '_[0-9]{0,4}_{0,1}')
                        group by $id
                        return $id
                        return $docs => count()
};




declare function ssrq-utils:listCantons($node as node(), $model as map(*)) as node()* {
    for $key in map:keys($ssrq-utils:CANTONS)
    order by $ssrq-utils:CANTONS($key)?order
    return
        if ($key => contains('-'))
        then ssrq-utils:renderMergedCantons($ssrq-utils:CANTONS($key))
        else ssrq-utils:renderCanton($key, $ssrq-utils:CANTONS($key))
};
