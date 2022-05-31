xquery version "3.1";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "modules/config.xqm";
import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xpath="http://www.w3.org/2005/xpath-functions";
declare namespace controller="http://ssrq-sds-fds.ch/exist/apps/controller";

import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "modules/utils.xqm";
import module namespace session="http://exist-db.org/xquery/session";
import module namespace console="http://exist-db.org/xquery/console";
declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $site-prefix := request:get-header('X-Site-Prefix');
declare variable $default-prefix := request:get-url() => substring-before('/exist') || '/exist/apps/ssrq';
declare variable $routeBase := '/routes/';
declare variable $language := map {
    'ssrq-online.ch': 'de',
    'fds-online.ch': 'it',
    'sds-online.ch': 'fr',
    'sls-online.ch': 'en'
};


declare function controller:setLanguage($key as xs:string*) {
    let $langParam := request:get-parameter("lang", ())
    let $lang := if ($key => exists() and $language($key)) then $language($key) else $langParam
    let $lang-selected := session:get-attribute("ssrq.lang")
    return
        if ($lang and $lang-selected and $lang-selected != $lang)
        then session:set-attribute("ssrq.lang", $lang)
        else if ($lang => empty() and $lang-selected)
        then session:set-attribute("ssrq.lang", $lang-selected)
        else if ($lang and $lang-selected => empty())
        then session:set-attribute("ssrq.lang", $lang)
        else session:set-attribute("ssrq.lang", "de")
};

declare function controller:setSessionPrefix ($prefix as xs:string*) {
    if (not(session:get-attribute('ssrq.prefix')))
    then
        if (not($prefix => exists()))
        then session:set-attribute('ssrq.prefix', $default-prefix)
        else session:set-attribute('ssrq.prefix', $prefix)
    else ()
};

(: Helper function to match the name of a route to a route specified in $main-routes :)
declare function controller:findRouteFromList($routes as map(*)+, $resource as xs:string, $error as node()) {
    let $route :=
                for $route in $routes
                let $analyzed-with-schema := $resource => analyze-string($route?schema)
                where $analyzed-with-schema/xpath:match
                return
                    if ($route => map:contains('params')) then
                        $route => map:put('params', map:merge(
                                for $param in $route?params => map:keys()
                                return
                                    map{$param: $analyzed-with-schema//xpath:group[@nr = $route?params($param)]/text()}
                            )
                        )
                    else $route
    let $log := console:log($route)
    return
        if (not($route => empty()))
        then
            if (not($resource => ends-with('/')) and $route?redirect)
            then
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <redirect url="{session:get-attribute('ssrq.prefix')}{$resource}/"/>
                </dispatch>
            else
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}{$route?file}"></forward>
                <view>
                    <forward url="{$exist:controller}/modules/view.xql">
                    {
                        if ($route => map:contains('params'))
                        then
                            for $param in $route?params => map:keys()
                            return
                                <add-parameter name="{$param}" value="{$route?params($param)}"/>
                        else (),
                        <add-parameter name="toggle-odd" value="true"/>[map:contains($route, 'toggle-odd') and $route?toggle-odd]
                    }
                        <set-header name="Cache-Control" value="no-cache"/>
                    </forward>
                </view>
                {$error}
            </dispatch>
        else
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}{$routeBase}error-page.html"></forward>
                <view>
                    <forward url="{$exist:controller}{$routeBase}error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </view>
            </dispatch>

};

let $set-prefix := controller:setSessionPrefix($site-prefix)
(: To-Do: Test if language Switching Works correct with urls... :)
(:~ let $lang := controller:setLanguage($site-prefix) ~:)
let $error-handler := <error-handler>
                        <forward url="{$exist:controller}/routes/error-page.html" method="get"/>
                        <forward url="{$exist:controller}/modules/view.xql"/>
                        </error-handler>

return

(: Redirect if path is empty :)
if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{session:get-attribute('ssrq.prefix')}/"/>
    </dispatch>

(: Serve Resources :)
else if (contains($exist:path, "/resources")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/{$exist:path => substring-after('/resources/')}"/>
    </dispatch>

(: Serve Resources generated by ODD-Transformation :)
else if (contains($exist:path, "/transform")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/transform/{substring-after($exist:path, '/transform/')}"/>
    </dispatch>

(: Handle content routes :)
else
    (
        let $resource := $exist:path
        (:~
        : This variable holds a list of main routes, with a static or a dynamic path
        : each route is expressed as a map(*) and needs to have a 'schema', 'file' and 'redirect'-key
        : the 'params' key is optional – if used, then each param is a key equal to the name of the param
        : and the value is the number of the catch-group used in the route-schema
        :)
        let $main-routes := (
                map {
                    'schema': '^/?$',
                    'file': $routeBase || 'index.html',
                    'redirect': false()
                },
                map {
                    'schema': '^/about/([a-z]*)$',
                    'file' : $routeBase || $resource => substring-after('about/') || '.html',
                    'redirect': false()
                },
                map {
                    'schema': '^/([A-Z]{2})/?$',
                    'file': $routeBase || 'index.html',
                    'params': map {
                        'kanton': '1'
                        },
                    'redirect': false()
                },
                map {
                    'schema': '^/([A-Z]{2})/([A-Za-z0-9_]+)/?$',
                    'file': $routeBase || 'index.html',
                    'params': map {
                        'kanton': '1',
                        'volume': '2'
                        },
                    'redirect': true()
                },
                map {
                    'schema': '^/([A-Z]{2})/([A-Za-z0-9_]+)/(intro|bailiffs|lit)\.html/?$',
                    'file': $routeBase || 'introduction.html',
                    'params': map {
                        'kanton': '1',
                        'volume': '2',
                        'doc': '3'
                        },
                    'redirect': true()
                },
                map {
                    'schema': '^/([A-Z]{2})/([A-Za-z0-9_]+)/((?:(?:(?:[A-Za-z0-9]+\.)*)(?:[0-9]+)-(?:[0-9]+)))\.html/?$',
                    'file': $routeBase || 'view.html',
                    'params': map {
                        'kanton': '1',
                        'volume': '2',
                        'doc': '3'
                        },
                    'redirect': true(),
                    'toggle-odd': true()
                }
            )
        return
            controller:findRouteFromList($main-routes, $resource, $error-handler)
    )
