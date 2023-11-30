xquery version "3.1";

module namespace views="http://ssrq-sds-fds.ch/exist/apps/ssrq/views";

import module namespace errors = "http://e-editiones.org/roaster/errors";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace router="http://e-editiones.org/roaster/router";
import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace util="http://exist-db.org/xquery/util";

(: ~
: The following are the views which will be rendered by the templating.
:)
import module namespace articles-idno="http://ssrq-sds-fds.ch/exist/apps/ssrq/articles/idno" at "articles/idno.xqm";
import module namespace find="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/finder" at "repository/finder.xqm";
import module namespace documents="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/documents" at "templates/documents.xqm";
import module namespace kantons="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/kantons" at "templates/kantons.xqm";
import module namespace volumes="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/volumes" at "templates/volumes.xqm";
import module namespace template-utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/utils" at "templates/template-utils.xqm";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

(:
 : The following modules provide functions which will be called by the
 : templating or used in the views.
 :)
import module namespace api="http://ssrq-sds-fds.ch/exist/apps/ssrq/api" at "api.xqm";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace app="http://ssrq-sds-fds.ch/exist/apps/ssrq/app" at "ssrq.xqm";
import module namespace browse="http://www.tei-c.org/tei-simple/templates" at "lib/browse.xqm";
import module namespace error="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/error" at "templates/error.xqm";
import module namespace i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/templates" at "i18n/i18n-templates.xqm";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "lib/pages.xqm";
import module namespace query="http://ssrq-sds-fds.ch/exist/apps/ssrq/search" at "ssrq-search.xqm";
import module namespace search="http://www.tei-c.org/tei-simple/search" at "lib/search.xqm";
import module namespace ssrq-cache="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/cache" at "./repository/ssrq-cache.xqm";
import module namespace ssrq-helper="http://ssrq-sds-fds.ch/exist/apps/ssrq/helper" at "ssrq-helper.xqm";
import module namespace tex="http://ssrq-sds-fds.ch/exist/apps/ssrq/processing/tex" at "processing/tex.xqm";
import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "utils.xqm";

declare variable $views:routes := map {
    'api' : 'api.html',
    'api-json' : 'api.json',
    'document' : 'document.html',
    'error' : 'error-page.html',
    'home' : 'index.html',
    'kanton-volumes': 'volumes.html',
    'paratexts': 'paratexts.html',
    'partners': 'partners.html',
    'volume-docs': 'documents.html'
};

declare variable $views:config := map {
    $templates:CONFIG_APP_ROOT : $config:app-root,
    $templates:CONFIG_STOP_ON_ERROR : true()
};

declare variable $views:lookup := function($functionName as xs:string, $arity as xs:int) {
    try {
        function-lookup(xs:QName($functionName), $arity)
    } catch * {
        ()
    }
};

declare function views:get-template-config($request as map(*)) {
    map:merge((
        $views:config,
        map {
            $templates:CONFIG_PARAM_RESOLVER : function($param as xs:string) {
                let $pval := array:fold-right(
                    [
                        request:get-parameter($param, ()),
                        if (map:contains($request, 'parameters')) then $request?parameters($param) else (),
                        request:get-attribute($param)
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

(: ~
: This handler serves all content routes under /about
:
: @param $request The request map
: @return The rendered page
: @throws 404 if the page does not exist
:)
declare function views:about-handler($request as map(*)) as node() {
    let $page := map:get($views:routes, $request?parameters?page)
    return
        if ($page) then
            views:render-view($request, $page)
        else
            error($errors:NOT_FOUND, 'Could not load: ' || $request?path)
};

declare function views:serve-api-definition($request as map(*)) as map(*) {
    let $api-definitions := json-doc(utils:path-concat-safe(($config:app-root, $views:routes?api-json)))
    return
        $api-definitions
        => map:put('servers', [map {'description': 'Server context of the API', 'url': $config:base-url}])
};

declare function views:error-handler($error) {
    let $template := doc(utils:path-concat-safe(($config:app-root, 'routes', $views:routes?error)))
    return
        templates:apply($template, $views:lookup, map { "description": $error?description }, views:get-template-config(map{}))
};


declare function views:home-handler($request as map(*)) as node() {
    views:handle-view-with-caching($request, $views:routes?home)
};

declare function views:volumes-per-kanton-handler($request as map(*)) as item() {
    if (not(ends-with($request?path, '/')))
    then
        router:response (301, "text/plain", "redirecting", map { "Location": utils:path-concat-safe(($config:base-url, $request?path, "/")) })
    else
        views:handle-view-with-caching($request, $views:routes?kanton-volumes)
};

declare function views:documents-per-volume-handler($request as map(*)) as item() {
    if (not(ends-with($request?path, '/')))
    then
        router:response (301, "text/plain", "redirecting", map { "Location": utils:path-concat-safe(($config:base-url, $request?path, "/")) })
    else
        views:handle-view-with-caching($request, $views:routes?volume-docs)
};

declare function views:volume-pdf-handler($request as map(*)) as item() {
    api:serve-pdf($request, false())
};

declare function views:single-handler($request as map(*)) as item()? {
    let $path-extension := substring-after($request?path, '.')
    return
        if (map:contains($request?parameters, 'doc')) then
            views:document-handler($request, $path-extension)
        else if (map:contains($request?parameters, 'paratext')) then
            views:paratext-handler($request, $path-extension)
        else
            error($errors:SERVER_ERROR, 'Missing doc or paratext parameter – cannot serve requested document')
};

declare %private function views:document-handler($request as map(*), $path-extension as xs:string) as item()? {
    switch ($path-extension)
        case 'html'
            return views:handle-view-with-caching($request, $views:routes?document)
        case 'pdf' case 'tex' case 'xml'
            return
                router:response (301, "text/plain", "redirecting", map { "Location": utils:path-concat-safe(($config:base-url, $config:api-prefix, $config:api-version, $request?path)) })
        default
            return error($errors:SERVER_ERROR, 'Requested view not implemented for documents')
};

declare %private function views:paratext-handler($request as map(*), $path-extension as xs:string) as item() {
    switch ($path-extension)
        case 'html'
            return views:handle-view-with-caching($request, $views:routes?paratexts)
        case 'tex' case 'xml'
            return
                router:response (301, "text/plain", "redirecting", map { "Location": utils:path-concat-safe(($config:base-url, $config:api-prefix, $config:api-version, $request?path)) })
        default
            return error($errors:SERVER_ERROR, 'Requested view not implemented for editorial paratexts')
};

declare %private function views:render-view($request as map(*), $route-name as xs:string) as node() {
    let $route-template-path := utils:path-concat-safe(($config:app-root, 'routes', $route-name))
    return
        if (doc-available($route-template-path)) then
            templates:apply(doc($route-template-path), $views:lookup, (), views:get-template-config($request))
        else
            error($errors:NOT_FOUND, 'Could not load template: ' || $route-name)
};

declare %private function views:handle-view-with-caching($request as map(*), $route-name as xs:string) {
    if ($request?use-cache) then
        let $cached-content := ssrq-cache:load-from-dynamic-cache($config:dynamic-cache-name, $request?cache-key)
        return
            if ($cached-content) then
                $cached-content
            else
                let $rendered-view := views:render-view($request, $route-name)
                return
                    (
                        ssrq-cache:store-in-dynamic-cache($config:dynamic-cache-name, $request?cache-key, $rendered-view),
                        $rendered-view
                    )[last()]
    else
        views:render-view($request, $route-name)
};
