xquery version "3.1";

import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "modules/config.xqm";
import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $logout := request:get-parameter("logout", ());
declare variable $login := request:get-parameter("user", ());
declare variable $site-prefix := request:get-header('X-Site-Prefix');
declare variable $default-prefix := '/exist/apps/ssrq';
declare variable $routeBase := '/routes/';
declare variable $language := map {
    'ssrq-online.ch': 'de',
    'fds-online.ch': 'it',
    'sds-online.ch': 'fr',
    'sls-online.ch': 'en'
};
declare variable $idnoSchema := '[A-Z]{3,4}_[A-Z]{2}_.*';


declare function local:setLanguage($key as xs:string*) {
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

declare function local:setSessionPrefix ($prefix as xs:string*) {
    if (not(session:get-attribute('ssrq.prefix')))
    then
        if (not($prefix => exists()))
        then session:set-attribute('ssrq.prefix', $default-prefix)
        else session:set-attribute('ssrq.prefix', $prefix)
    else ()
};

declare function local:resolveId($id as xs:string) as xs:string {
    if ($id => matches($idnoSchema))
    then
        if (collection($config:data-root)/tei:TEI[tei:teiHeader//tei:seriesStmt/tei:idno = $id])
        then $id
        else $id || "_1"
    else $id

};

declare function local:resolveView($error as node()) {
    let $type := $exist:resource => substring-after('.') => functx:substring-before-if-contains('?')
    let $id := xmldb:decode($exist:resource)
    let $path := substring-before($exist:path, $exist:resource)
    return
        local:handleResolveCases($type, $path, $id, $error)
};

(: Helper function to match the name of a route to a route specified in $main-routes :)
declare function local:findRouteFromList($routes as map(*), $resource as xs:string, $error as node()) {
    let $route := for $key in $routes => map:keys()
                    return
                        if ($resource => matches($routes($key)?schema))
                        then $routes($key)
                        else ()
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
                        else ()
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

(: Helper function to handle .views :)
declare function local:handleResolveCases($type as xs:string, $path as xs:string, $id as xs:string, $error as node()) {
    switch ($type)
            case 'html'
            return
                let $template := request:get-parameter('template', ())
                let $route := if ($template and $template = 'introduction') then $routeBase || 'introduction.html' else $routeBase || 'view.html'
                return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{$exist:controller}{$route}"></forward>
                        <view>
                            <forward url="{$exist:controller}/modules/view.xql">
                                {
                                if ($id => matches($idnoSchema))
                                then
                                (: This will load texts by their tei:idno instead of using the filename :)
                                <add-parameter name="id" value="{$id => replace('.html', '')}"/>
                                else ()
                                }
                                <add-parameter name="doc" value="{$path}{$id => replace('.html', '.xml')}"/>
                                <set-header name="Cache-Control" value="no-cache"/>
                            </forward>
                        </view>
                        {$error}
                    </dispatch>
            case 'xml'
            return
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward url="{$exist:controller}/modules/ssrq-rest.xql">
                        {
                        if ($id => matches($idnoSchema))
                        then

                        <add-parameter name="id" value="{$id => replace('.xml', '')}"/>
                        else ()
                        }
                        <add-parameter name="route" value="xml"/>
                        <add-parameter name="doc" value="{$path}{$id}"/>
                    </forward>
                    {$error}
                </dispatch>
            case 'tex'
            return
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward url="{$exist:controller}/modules/lib/latex.xql">
                        <add-parameter name="id" value="{$path}{($id => substring-before('.tex') => local:resolveId()) || '.xml'}"/>
                    </forward>
                    {$error}
                </dispatch>
            case 'pdf'
            return
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward url="{$exist:controller}/modules/ssrq-rest.xql">
                        <add-parameter name="doc" value="{$path}pdf/{$id => replace('_[0-9].pdf', '.pdf')}"/>
                        <add-parameter name="route" value="pdf"/>
                    </forward>
                    {$error}
                </dispatch>
            default return
                (: Error Handling for old .xml.tex :)
                if ($type => contains('.'))
                then local:handleResolveCases($type => substring-after('.'), $path, $id => functx:substring-before-last('.'), $error)
                else $error
};

let $set-prefix := local:setSessionPrefix($site-prefix)
(: To-Do: Test if language Switching Works correct with urls... :)
(:~ let $lang := local:setLanguage($site-prefix) ~:)
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


(: Handle User Login-State :)
else if (request:get-method() = 'POST' and $login or $logout) then
    let $lang := session:get-attribute("ssrq.lang")
    return
    (
        login:set-user($config:login-domain, (), false()),
        session:create(),
        try {
            local:setSessionPrefix($site-prefix),
            session:set-attribute("ssrq.lang", $lang)
        } catch * {()},
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <redirect url="{session:get-attribute('ssrq.prefix')}/{request:get-uri() => substring-after($default-prefix)}"/>
        </dispatch>
    )

(: Handle all Routes with a ., except /templates/xyz.html :)
else if ($exist:resource => contains('.') and not(contains($exist:path, "/templates/"))) then
    (
        login:set-user($config:login-domain, (), false()),
        local:resolveView($error-handler)
    )

(: Handle all the rest :)
else
    (
        login:set-user($config:login-domain, (), false()),
        let $resource := $exist:path
        (: This variable holds a list of main-routes – with a static or dynamic path :)
        let $main-routes := map {
            'about': map {
                'schema': '/about/[a-z]*',
                'file' : $routeBase || $resource => substring-after('about/') || '.html',
                'redirect': false()
            },
            'templates': map {
                'schema': '/templates/[a-z]*',
                'file': '/templates/' || $resource => substring-after('templates/'),
                'redirect': false()
            },
            'start': map {
                'schema': '^/$',
                'file': $routeBase || 'index.html',
                'redirect': false()
            },
            'canton': map {
                'schema': '^/[A-Z]{2}/?$',
                'file': $routeBase || 'index.html',
                'params': map {
                    'collection': $resource => substring(2,2)
                    },
                'redirect': true()
            },
            'volume': map {
                'schema': '^/[A-Z]{2}/.*[\S]/?$',
                'file': $routeBase || 'index.html',
                'params': map {
                    'collection': $resource => substring(2,2),
                    'volume': $resource => substring(4) => replace('/', '')
                    },
                'redirect': true()
            }}
        return
            local:findRouteFromList($main-routes, $resource, $error-handler)

    )
