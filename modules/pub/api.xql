xquery version "3.1";
(:~
: A simple REST-API, which can be accessed via /api
: – requests ending with .xql are also handled by this script
:
: @author: Bastian Politycki
: @date: 2022-05-22
: @return result per endpoint as json or xml
:
:)

import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "../lib/pages.xqm";
import module namespace app="http://ssrq-sds-fds.ch/exist/apps/ssrq/app" at "../ssrq.xqm";
import module namespace id-search="http://ssrq-sds-fds.ch/exist/apps/ssrq/id-search" at "../id-search.xqm";
import module namespace index="http://ssrq-sds-fds.ch/exist/apps/ssrq/index" at "../index.xqm";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace response="http://exist-db.org/xquery/response";

declare namespace api = "http://ssrq-sds-fds.ch/exist/apps/ssrq/api";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare variable $api:jsonSerializationParams := <output:serialization-parameters
        xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
    <output:method value="json"/>
    <output:media-type value="application/json"/>
</output:serialization-parameters>;


let $route := request:get-parameter("route", ())
return
    switch($route)
    (: To-Do: Implement more endpoints! :)
    (: Load all index-entries for a single document and return the result as html :)
    case 'facets'
        return
            let $resp := request:get-parameter("doc", "") => index:get-index-entries()
            return
                $resp
    case 'id-search'
        return
            let $resp := request:get-parameter("id", "") => id-search:search()
            return
                if (xs:boolean(request:get-parameter("json", ('false')))) then
                (response:set-header('Content-Type', 'application/json'), serialize($resp, $api:jsonSerializationParams))
                else $resp
    default return
        serialize(map {
            "error": "No route found for '" || $route || "'"
        }, $api:jsonSerializationParams)
