xquery version "3.1";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace ssrq-utils="http://existsolutions.com/ssrq/utils" at "ssrq-util.xqm";
import module namespace http = "http://expath.org/ns/http-client";

declare namespace ssrq-static="http://existsolutions.com/ssrq/static";
declare default element namespace "http://www.w3.org/1999/xhtml";

declare variable $ssrq-static:path := $config:app-root || '/static';
declare variable $ssrq-static:languages := ['de', 'fr', 'en'];
declare variable $ssrq-static:debug := false();

declare function ssrq-static:generateUrl($template as xs:string, $params as map(*)) as xs:string {
    let $baseUrl := 'http://localhost:' || request:get-server-port() || $config:app-root => replace('db', 'exist') || '/templates/'
    let $query-params :=    for $param at $pos in $params => map:keys()
                            return
                                if ($pos = 1)
                                then '?' || $param || '=' || $params($param)
                                else '&amp;' || $param || '=' || $params($param)
    return
        $baseUrl || $template || $query-params => string-join('')

};

declare function ssrq-static:fetch($url as xs:string) as node()* {
    let $req := <http:request href="{$url}" method="GET"/>
    let $result :=  http:send-request($req)[2]
    return $result
};

declare function ssrq-static:getPages($pages as map(*)) as array(*) {
    array {
    for $value in 1 to $ssrq-static:languages => array:size()
    let $lang := $ssrq-static:languages($value)
    let $entry :=
        for $page in $pages => map:keys()
        let $filename := $pages($page)?template
        let $params := map:merge((map:entry("lang", $lang), $pages($page)?params))
        let $url := ssrq-static:generateUrl($filename, $params)
        let $data := ssrq-static:fetch($url)
        return
            map {
                "static-filename": $pages($page)?file || '_' || $lang || '.html',
                "request-url": $url,
                "content": $data
            }
    return $entry
    }
};

declare function ssrq-static:storePages($pages as array(*)) {
    for $item in 1 to array:size($pages)
    return
        if ($ssrq-static:debug)
        then $pages($item)
        else xmldb:store($ssrq-static:path, $pages($item)?static-filename, $pages($item)?content)
};

declare function ssrq-static:addVolumesToPagelist($pages as map(*)) {
    let $volumes := map:merge(
        let $cantons := for $canton in ssrq-utils:listCantons(<div/>, map{})
                        return $canton/node()[2]/node()[@data-collection]/@data-collection/data(.)
        for $canton in $cantons
        return
            map:entry("volumes-" || $canton, map {
                "template": "volumes.html",
                "params": map {
                    "collection": $canton
                },
                "file": "volumes_" || $canton
            })
    )
    return map:merge(($pages, $volumes))
};

let $pages := map {
    "cantons": map {
        "template": "cantons.html",
        "params": map{},
        "file": "cantons"
    }
}

return $pages => ssrq-static:addVolumesToPagelist() => ssrq-static:getPages() => ssrq-static:storePages()
