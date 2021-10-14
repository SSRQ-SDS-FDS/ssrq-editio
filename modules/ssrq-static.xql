xquery version "3.1";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace http = "http://expath.org/ns/http-client";

declare default element namespace "http://www.w3.org/1999/xhtml";

let $baseUrl := 'http://localhost:' || request:get-server-port() || '/' || $config:app-root => replace('db', 'exist') || '/templates/'
let $staticPath := $config:app-root || '/static'

let $pages := map {
    "cantons": map {
        "file": "cantons.html"
    }
}

for $page in $pages => map:keys()
    let $file := $pages($page)?file
    let $params := $pages($page)?params
    let $req := <http:request href="{$baseUrl || $file || $params}" method="GET"/>
    let $result :=  http:send-request($req)[2]
return
    xmldb:store($staticPath, $pages($page)?file, $result//body/node())
