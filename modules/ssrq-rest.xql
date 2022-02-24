xquery version "3.1";
(:~
: Just a simple REST-API
:
:)

import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "lib/pages.xqm";
import module namespace app="http://existsolutions.com/ssrq/app" at "ssrq.xqm";

declare namespace api = "http://existsolutions.com/ssrq/api";

declare namespace request = "http://exist-db.org/xquery/request";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";
declare option output:indent "yes";

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
    let $path := request:get-attribute("$exist:path") => substring-after('api/')
    let $route := $path => tokenize('/') => head()
    return
        switch($route)
        (: Route >>> /persons?doc=XYZ.xml :)
        case 'persons'
        return
            let $doc := request:get-parameter("doc", "")
            let $xml := pages:load(<div/>, map{}, $doc, (), (), ())
            let $data := api:list-persons($xml)
            return
                map {
                    "doc": $doc,
                    "persons": $data
                }
        default return
            map {
                "error": "No route found for '" || $route || "'"
            }
};


api:main()
