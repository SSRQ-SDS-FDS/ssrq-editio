import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace functx="http://www.functx.com";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace html="http://www.w3.org/1999/xhtml";


declare variable $local:TEMP_DOCS := collection($config:temp-root)/tei:TEI;
declare variable $local:ALL_DOCS := collection($config:data-root);
declare variable $local:SPECIAL_DOCS := collection($config:data-root)/tei:TEI[@type];

declare function local:renderCanton($key as xs:string, $data as map(*)) {
    <div class="canton">
        <div class="canton__name">
            <img src="{concat('resources/images/kantone/', $data?img)}"/>
            <span>{$key}</span>
        </div>
        {local:renderDepartment($data,$key)}
    </div>
};

declare function local:renderMergedCantons($data as map(*)) {
    let $keys :=  map:keys($data)
    return
    <div class="canton">
        <div class="canton__name--container">
            {
               for $key in $keys[not(. = 'order')]
                return
                    <div class="canton__name">
                        <img src="{concat('resources/images/kantone/', $data($key)?img)}"/>
                        <span>{$key}</span>
                    </div>
            }
        </div>
        <div class="canton__department">
            <a>{$data($keys[1])?department}</a>
        </div>
        <div class="canton__badge"></div>
    </div>
};

declare function local:renderDepartment($data as map(*), $dep as xs:string) {
    let $rootCollection := $config:data-root || '/' || $dep
    return
    if (xmldb:collection-available($rootCollection))
    then
        (<div class="canton__department">
            <a href="#" data-collection="{$dep}">
                {
                let $html := $data?department => util:parse-html()
                return $html//html:body/node()}
            </a>
        </div>,
        <div class="canton__badge">
            <span class="badge">{
                sum(let $childCollections := xmldb:get-child-collections($rootCollection)
                for $collection in $childCollections
                return local:countDocs($rootCollection || '/' || $collection, $collection))
            }</span>
        </div>)
    else
        <div class="canton__department">
            <p>{
                let $html := $data?department => util:parse-html()
                return $html//html:body/node()
            }</p>
        </div>
};

declare function local:countDocs($path as xs:string, $idno as xs:string) {
    let $docs := for $doc in collection($path)/tei:TEI except(
                          $local:TEMP_DOCS union
                          $local:SPECIAL_DOCS
                        )
               let $id := $doc//tei:seriesStmt[@xml:id = 'ssrq-sds-fds']/tei:idno => functx:get-matches($idno || '_[0-9]{0,4}_{0,1}')
                        group by $id
                        return $id
                        return $docs => count()
};


let $CANTONS := util:binary-doc($config:app-root || '/resources/json/cantons.json')  => util:binary-to-string() => parse-json()

for $key in map:keys($CANTONS)
order by $CANTONS($key)?order
return
    (:if (collection($config:data-root || '/' || $key) => exists())
    then ($key, local:countDocs(collection($config:data-root || '/' || $key), $key))
    else $key:)
    if ($key => contains('-'))
    then local:renderMergedCantons($CANTONS($key))
    else local:renderCanton($key, $CANTONS($key))
