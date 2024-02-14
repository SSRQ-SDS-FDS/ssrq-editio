xquery version "3.1";

declare namespace ssrq-router="http://ssrq-sds-fds.ch/exist/apps/ssrq/router";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization"; (: required for serialization :)

import module namespace roaster="http://e-editiones.org/roaster";
import module namespace router="http://e-editiones.org/roaster/router";
import module namespace rutil="http://e-editiones.org/roaster/util";
import module namespace errors="http://e-editiones.org/roaster/errors";
import module namespace auth="http://e-editiones.org/roaster/auth";
import module namespace util="http://exist-db.org/xquery/util";

import module namespace api="http://ssrq-sds-fds.ch/exist/apps/ssrq/api" at "api.xqm";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace path="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils/path" at "utils/path.xqm";
import module namespace ssrq-cache="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/cache" at "../repository/cache.xqm";
import module namespace views="http://ssrq-sds-fds.ch/exist/apps/ssrq/views" at "views.xqm";

declare variable $ssrq-router:definitions := ("views.json", "api.json");
declare variable $ssrq-router:params-to-rewrite := ('kanton', 'volume');
declare variable $ssrq-router:id-param-name := 'id';

(:~
 : This function "knows" all modules and their functions
 : that are imported here
 : You can leave it as it is, but it has to be here
 :)
declare function ssrq-router:lookup ($name as xs:string) {
    function-lookup(xs:QName($name), 1)
};

(:~
 : This function rewrites the parameters set in $params-to-rewrite.
 : The ending slash is removed from the parameter value.
 :
 : @param $request as map(*) The request with the parameters to be rewritten.
 : @param $parameters-to-rewrite as xs:string+ The names of the parameters to be rewritten.
 : @return map(*) The request with the rewritten parameters.
 :)
declare function ssrq-router:rewrite-params($request as map(*), $parameters-to-rewrite as xs:string+, $special-id-param as xs:string) as map(*) {
    let $parameters := $request?parameters
    let $required-parameters := map{'request-path': $request?path, 'lang': ($parameters?lang, $config:lang-settings?lang)[1]}
    return
        if (empty($parameters)) then
            map:put($request, 'parameters', map:merge($required-parameters))
        else
            let $parameters-rewritten :=
                    map:for-each($parameters, function($key, $value) {
                        if ($key = $parameters-to-rewrite) then
                            map:entry($key, replace($value, "^(.*)/$", "$1"))
                        else if ($key = $special-id-param) then
                            let $name := path:get-filename($value, false())
                            return
                                map:entry(
                                    if ($name = $config:paratext-types) then 'paratext' else 'doc',
                                    $name
                                )
                        else map:entry($key, $value)
                    })
            let $rewritten-with-required-parameters := map:merge(($parameters-rewritten, $required-parameters))
            return
                map:put($request, 'parameters', $rewritten-with-required-parameters)
};

(:~
 : This function adds the cache info to the request.
 : The cache key is created from the path and the parameters.
 : The cache key is unique for each request.
 :
 : @param $request as map(*) The request.
 : @return map(*) The request with the cache info.
 :)
declare function ssrq-router:add-cache-info($request as map(*)) as map(*) {
    if (xs:boolean($config:env/cache/text())) then
        let $parameters := if (empty($request?parameters)) then () else (map:keys($request?parameters)[not(. = 'lang')] ! $request?parameters(.))
        let $cache-key := ssrq-cache:create-unique-cache-key-as-uuid($request?path, $parameters, $request?parameters?lang)
        return
            map:merge(($request, map{'use-cache': true(), 'cache-key': $cache-key}))
    else
        map:put($request, 'use-cache', false())
};

declare function ssrq-router:params-cache-middleware ($request as map(*), $response as map(*)) as map(*)+ {
    ssrq-router:add-cache-info(
        ssrq-router:rewrite-params($request, $ssrq-router:params-to-rewrite, $ssrq-router:id-param-name)
    ),
    $response
};

declare variable $ssrq-router:middleware := (
    ssrq-router:params-cache-middleware#2
);
roaster:route($ssrq-router:definitions, ssrq-router:lookup#1, $ssrq-router:middleware)
