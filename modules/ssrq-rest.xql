xquery version "3.1";
(:~
: Just a simple REST-API
:
:)

import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "lib/pages.xql";
import module namespace app="http://existsolutions.com/ssrq/app" at "ssrq.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare namespace api = "http://existsolutions.com/ssrq/api";

declare namespace request = "http://exist-db.org/xquery/request";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare variable $api:jsonSerializationParams := <output:serialization-parameters
        xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
    <output:method value="json"/>
    <output:media-type value="application/json"/>
</output:serialization-parameters>;

declare function api:list-persons($model as map(*)) {
    let $persons :=
        root($model?data)//tei:persName/@ref |
        root($model?data)//@scribe[starts-with(., 'per')]
    where exists($persons)
    return
        array {
            for $person in app:api-lookup($app:PERSONS, app:api-keys($persons), "ids_search")?*
            order by $person?name
            return
                $person
        }
};


declare function api:main() {
    let $route := request:get-parameter("route", ())
    return
        switch($route)
        (: Route >>> /persons?doc=XYZ.xml :)
        case 'persons'
        return
            let $doc := request:get-parameter("doc", "")
            let $xml := pages:load(<div/>, map{}, $doc, (), (), ())
            let $data := api:list-persons($xml)
            return
                serialize(map {
                    "doc": $doc,
                    "persons": $data
                }, $api:jsonSerializationParams)
        case 'xml'
        return
            let $data := app:load(<div/>, map{}, request:get-parameter("doc", ""), (), request:get-parameter("id", ""), ())
            return
                root($data?data)
        case 'pdf'
        return
            let $path := request:get-parameter("doc", "")
            let $doc := $config:data-root || $path
            return
                if ($doc => util:binary-doc-available())
                then $doc => util:binary-doc() => response:stream-binary("media-type=application/pdf", $path => substring-after('_pdf_'))
                else <error>Did not found {$doc}</error>
        default return
            serialize(map {
                "error": "No route found for '" || $route || "'"
            }, $api:jsonSerializationParams)
};


api:main()
