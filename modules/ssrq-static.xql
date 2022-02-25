xquery version "3.1";

import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xqm";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace ssrq-utils="http://existsolutions.com/ssrq/utils" at "ssrq-util.xqm";

import module namespace i18n="http://exist-db.org/xquery/i18n/templates" at "lib/i18n-templates.xqm";

declare namespace ssrq-static="http://existsolutions.com/ssrq/static";
declare default element namespace "http://www.w3.org/1999/xhtml";


declare variable $ssrq-static:path := $config:app-root || '/static';
declare variable $ssrq-static:languages := ['de', 'fr', 'en'];
declare variable $ssrq-static:debug := false();
declare variable $ssrq-static:cantons := ssrq-utils:listCantons(<div/>, map{})//node()[@data-collection]/@data-collection/data(.);
declare variable $ssrq-static:config := map {
    $templates:CONFIG_APP_ROOT : $config:app-root,
    $templates:CONFIG_STOP_ON_ERROR : true()};

declare function ssrq-static:get-template-config($config as map(*), $parameters as map(*)) {
    map:merge((
        $config,
        map {
            $templates:CONFIG_PARAM_RESOLVER : function($param) {
                let $pval := array:fold-right(
                    [
                        $parameters($param)
                    ], (),
                    function($zero, $current) {
                        if (exists($zero)) then
                            $zero
                        else
                            $current
                    }
                )
                return
                    $pval
            }
        }))
};


declare function ssrq-static:applyTemplates($name as xs:string, $params as map(*)) {
    let $template := doc($config:app-root || '/templates/' || $name)
    let $lookup := function($functionName as xs:string, $arity as xs:int) {
        try { function-lookup(xs:QName($functionName), $arity) }
        catch * {()}
    }
    return
        templates:apply($template, $lookup, (), ssrq-static:get-template-config($ssrq-static:config, $params))
};


declare function ssrq-static:getPages($pages as map(*)) as array(*) {
    array {
    for $value in 1 to $ssrq-static:languages => array:size()
    let $lang := $ssrq-static:languages($value)
    let $entry :=
        for $page in $pages => map:keys()
        let $filename := $pages($page)?template
        let $params := map:merge((map:entry("lang", $lang), $pages($page)?params))
        let $data := ssrq-static:applyTemplates($filename, $params)
        return
            map {
                "static-filename": $pages($page)?file || '_' || $lang || '.html',
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
        for $canton in $ssrq-static:cantons
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

declare function ssrq-static:addWorksToPagelist($pages as map(*)) {
    let $works := map:merge(
        for $canton in $ssrq-static:cantons
            return
                let $volumes := ssrq-utils:listVolumes(<div/>, map{}, $canton)
                for $volume in $volumes//node()[@data-works]/@data-works/data(.)
                return
                     map:entry("works_" || $volume, map {
                            "template": "works.html",
                            "file": "works_" || $volume,
                            "params": map {
                                "collection": $canton,
                                "volume": $volume
                            }
                        })
    )
    return map:merge(($pages, $works))
};


let $pages := map {
    "cantons": map {
        "template": "cantons.html",
        "params": map{},
        "file": "cantons"
    }
}

return $pages => ssrq-static:addVolumesToPagelist() => ssrq-static:addWorksToPagelist() => ssrq-static:getPages() => ssrq-static:storePages()
