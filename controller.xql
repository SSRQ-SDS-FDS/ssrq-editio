xquery version "3.1";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "modules/config.xqm";
import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xpath="http://www.w3.org/2005/xpath-functions";
declare namespace controller="http://ssrq-sds-fds.ch/exist/apps/controller";

import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "modules/utils.xqm";
import module namespace session="http://exist-db.org/xquery/session";
import module namespace request="http://exist-db.org/xquery/request";
import module namespace console="http://exist-db.org/xquery/console";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;
declare variable $routeBase := '/routes/';


declare function controller:setLanguage() {
    let $lang-param := request:get-parameter("lang", ())
    let $lang-selected := session:get-attribute("ssrq.lang")
    return
        if ($lang-selected and $lang-selected != $lang-param)
        then session:set-attribute("ssrq.lang", $lang-param)
        else if ($lang-param => empty() and $lang-selected)
        then session:set-attribute("ssrq.lang", $lang-selected)
        else if ($lang-param and $lang-selected => empty())
        then session:set-attribute("ssrq.lang", $lang-param)
        else session:set-attribute("ssrq.lang", "de")
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
                    let $group := $analyzed-with-schema//xpath:group[@nr = $route?params($param)]/text()
                    where not(empty($group))
                    return
                        map{$param: $group}
                    )
                )
            else
                $route
    let $log := console:log($route)
    return
        if (not($route => empty()))
        then
            if (not($resource => ends-with('/')) and ($route?redirect-slash, false())[1])
            then
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <redirect url="{$config:base-url}{$resource}/"/>
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
                            where exists($param)
                            return
                                <add-parameter name="{$param}" value="{$route?params($param)}"/>
                        else (),
                        <add-parameter name="toggle-odd" value="true"/>[map:contains($route, 'toggle-odd') and $route?toggle-odd]
                    }
                        <set-header name="Cache-Control" value="no-cache"/>
                    {
                        if($route => map:contains('type')) then
                            <set-header name="Content-Type" value="{$route?type}"/>
                        else ()
                    }
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

(: To-Do: Test if language Switching Works correct with urls... :)
let $lang := controller:setLanguage()
let $error-handler := <error-handler>
                        <forward url="{$exist:controller}/routes/error-page.html" method="get"/>
                        <forward url="{$exist:controller}/modules/view.xql"/>
                        </error-handler>
return

(: Redirect if path is empty :)
if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{$config:base-url}/"/>
    </dispatch>

(: Serve Resources :)
else if (contains($exist:path, "/resources")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/{$exist:path => substring-after('/resources/')}"/>
    </dispatch>

(: Serve Resources from /assets subfolder per volume :)
else if (contains($exist:path, "assets")) then
    let $resource := $config:data-root || $exist:path
    return
        if ($resource => util:binary-doc-available()) then
            response:stream-binary($resource => util:binary-doc(), 'image/' || ($resource => tokenize('.'))[last()], $exist:resource)
        else
            response:set-status-code(404)

(: Serve Resources generated by ODD-Transformation :)
else if (contains($exist:path, "/transform")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/transform/{substring-after($exist:path, '/transform/')}"/>
    </dispatch>

else if (contains($exist:path, 'upload') or contains($exist:path, 'temp')) then
    if (xs:boolean(doc(utils:path-concat-safe(($config:app-root, 'env.xml')))//upload)) then
        switch (request:get-method())
            case 'POST'
                return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{$exist:controller}/modules/pub/upload.xql"/>
                    </dispatch>
            default
                return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{$exist:controller}{$routeBase}temp.html"/>
                        <view>
                            <forward url="{$exist:controller}/modules/view.xql">
                                <add-parameter name="file" value="{$exist:resource => replace('.html', '.xml')}"/>
                                <add-parameter name="toggle-odd" value="true"/>
                            </forward>
                        </view>
                    </dispatch>
    else
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}{$routeBase}error-page.html"/>
            <view>
                <forward url="{$exist:controller}{$routeBase}error-page.html" method="get"/>
                <forward url="{$exist:controller}/modules/view.xql"/>
            </view>
        </dispatch>

else if (ends-with($exist:resource, '.xql')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/pub/api.xql">
             <add-parameter name="route" value="{replace($exist:resource, '-json', '') => substring-before('.xql')}"/>
             <add-parameter name="json" value="{if(matches($exist:resource, 'json')) then 'true' else 'false'}"/>
        </forward>
    </dispatch>

else if (contains($exist:path, 'api')) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/pub/api.xql">
             <add-parameter name="route" value="{$exist:resource}"/>
        </forward>
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
                    'file': $routeBase || 'index.html'
                },
                map {
                    'schema': '^/about/([a-z]*)$',
                    'file' : $routeBase || $resource => substring-after('about/') || '.html'
                },
                map {
                    'schema': '^/([A-Z]{2})/?$',
                    'file': $routeBase || 'index.html',
                    'params': map {
                        'kanton': '1'
                        },
                    'redirect-slash': true()
                },
                map {
                    'schema': '^/([A-Z]{2})/([A-Za-z0-9_]+)/?$',
                    'file': $routeBase || 'index.html',
                    'params': map {
                        'kanton': '1',
                        'volume': '2'
                        },
                    'redirect-slash': true()
                },
                map {
                    'schema': '^/search$',
                    'file': $routeBase || 'search.html'
                },
                map {
                    'schema': '^/([A-Z]{2})/([A-Za-z0-9_]+)/(intro|bailiffs|lit)\.html$',
                    'file': $routeBase || 'introduction.html',
                    'params': map {
                        'kanton': '1',
                        'volume': '2',
                        'doc': '3'
                    }
                },
                map {
                    'schema': '^/([A-Z]{2})/([A-Za-z0-9_]+)/((?:[A-Za-z0-9]+\.)*[0-9]+-[0-9]+)\.html$',
                    'file': $routeBase || 'view.html',
                    'params': map {
                        'kanton': '1',
                        'volume': '2',
                        'doc': '3'
                        },
                    'toggle-odd': true()
                },
                map {
                    'schema': '^/([A-Z]{2})/([A-Za-z0-9_]+)/((?:[A-Za-z0-9]+\.)*[0-9]+-[0-9]+|[a-z]{3,})\.xml$',
                    'file': $routeBase || 'xml.html',
                    'params': map {
                        'kanton': '1',
                        'volume': '2',
                        'doc': '3'
                        },
                    'type': 'text/xml'
                },
                map {
                    (: NOTE: schema must match whole volume links (e.g. /SG/III_4.pdf) and document links (e.g. /SG/III_4/1-1.pdf) :)
                    'schema': '^/([A-Z]{2})/([A-Za-z0-9_]+)(?:/((?:[A-Za-z0-9]+\.)*[0-9]+-[0-9]+|[a-z]{3,}))?\.pdf$',
                    'file': $routeBase || 'pdf.html',
                    'params': map {
                        'kanton': '1',
                        'volume': '2',
                        'doc': '3'
                        },
                    'type': 'application/pdf'
                },
                map {
                    'schema': '^/([A-Z]{2})/([A-Za-z0-9_]+)/((?:[A-Za-z0-9]+\.)*[0-9]+-[0-9]+|[a-z]{3,})\.tex$',
                    'file': $routeBase || 'tex.html',
                    'params': map {
                        'kanton': '1',
                        'volume': '2',
                        'doc': '3'
                        },
                    'type': 'text/text;charset=UTF-8'
                }
            )
        return
            controller:findRouteFromList($main-routes, $resource, $error-handler)
    )
