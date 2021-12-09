xquery version "3.1";

import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "modules/config.xqm";
import module namespace functx="http://www.functx.com";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $logout := request:get-parameter("logout", ());
declare variable $login := request:get-parameter("user", ());
declare variable $site-prefix := request:get-header('X-Site-Prefix');
declare variable $routeBase := '/routes/';
declare variable $language := map {
    'ssrq-online.ch': 'de',
    'fds-online.ch': 'it',
    'sds-online.ch': 'fr',
    'sls-online.ch': 'en'
};

declare function local:setLanguage($key as xs:string) {
    let $lang := if ($language($key)) then $language($key) else request:get-parameter("lang", "de")
    return
       if (session:get-attribute("ssrq.lang") != $lang)
       then session:set-attribute("ssrq.lang", $lang)
       else ()
};

declare function local:resolveView($error as node()) {
    let $type := $exist:resource => substring-after('.') => functx:substring-before-if-contains('?')
    let $id := xmldb:decode($exist:resource)
    let $path := substring-before($exist:path, $exist:resource)
    return
        local:handleResolveCases($type, $path, $id, $error)
};

declare function local:handleResolveCases($type as xs:string, $path as xs:string, $id as xs:string, $error as node()) {
    switch ($type)
            case 'html'
            return ()
            case 'xml'
            return
                 let $template := request:get-parameter("template", ())
                 let $route := if ($template and $template = 'introduction') then $routeBase || 'introduction.html' else $routeBase || 'view.html'
                 return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{$exist:controller}{$route}"></forward>
                        <view>
                            <forward url="{$exist:controller}/modules/view.xql">
                                <add-parameter name="id" value="{$id => replace('.xml', '')}"/>
                                <add-parameter name="doc" value="{$path}{$id}"/>
                                <set-header name="Cache-Control" value="no-cache"/>
                            </forward>
                        </view>
                        {$error}
                    </dispatch>
            case 'tex'
            return
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward url="{$exist:controller}/modules/lib/latex.xql">
                        <add-parameter name="id" value="{$path}{$id => replace('.tex', '.xml')}"/>
                    </forward>
                    {$error}
                </dispatch>
            case 'pdf'
            return ()
            default return
                (: Error Handling for old .xml.tex :)
                if ($type => contains('.'))
                then local:handleResolveCases($type => substring-after('.'), $path, $id => functx:substring-before-last('.'), $error)
                else $error
};


declare function local:resolve($path as xs:string, $name as xs:string) {
    if (doc-available(``[`{$config:data-root}`/`{$path}`/`{$name}`]``)) then
        ()
    else
        let $basename := replace($name, "^([^\.]+)\..*$", "$1")
        let $suffix := replace($name, "^[^\.]+(\..*)$", "$1")
        let $name := $basename || "_1" || $suffix
        return
            if (doc-available(``[`{$config:data-root}`/`{$path}`/`{$name}`]``)) then
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <redirect url="{replace(request:get-uri(), '^(.*/ssrq/).*$', '$1')}{$path}/{$name}"/>
                </dispatch>
            else
                ()
};

let $set-prefix := if ($site-prefix => exists()) then session:set-attribute('ssrq.prefix', '/exist/apps/ssrq') else session:set-attribute('ssrq.prefix', $site-prefix)
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

(: Handle User Login-State :)
else if ($login or $logout) then
   (login:set-user($config:login-domain, (), false()),
    (:session:create(),:)
    local:setLanguage($site-prefix),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="{session:get-attribute('ssrq.prefix')}/{$exist:path}/{$exist:resource}"/>
    </dispatch>
    )

else if ($exist:resource => contains('.')) then
    (login:set-user($config:login-domain, (), false()),
    local:resolveView($error-handler))
else ()
(:~


else if (ends-with($exist:resource, ".html")) then (
    login:set-user($config:login-domain, (), false()),
    let $resource :=
        if (contains($exist:path, "/templates/")) then
            "templates/" || $exist:resource
        else
            "routes/" || $exist:resource
    return
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/{$resource}">
                <set-header name="Cache-Control" value="no-cache"/>
            </forward>
            <view>
                <forward url="{$exist:controller}/modules/view.xql"/>
            </view>
    		<error-handler>
    			<forward url="{$exist:controller}/routes/error-page.html" method="get"/>
    			<forward url="{$exist:controller}/modules/view.xql"/>
    		</error-handler>
        </dispatch>

) else (
    login:set-user($config:login-domain, (), false()),
    let $id := xmldb:decode($exist:resource)
    let $path := substring-before($exist:path, $exist:resource)
    let $redir := local:resolve($path, $id)
    return
        if ($redir) then
            $redir
        else
    let $mode := request:get-parameter("mode", ())
    let $facsimiles := request:get-parameter("facs", ())
    let $template := request:get-parameter("template", ())
    let $html :=
        if ($exist:resource = "" and not(request:get-parameter("id", ()))) then
            "routes/index.html"
        else if ($exist:resource = "doc-table.html") then
            "templates/doc-table.html"
        else if ($exist:resource = ("search.html", "toc.html")) then
            "routes/" || $exist:resource
        else if ($facsimiles) then
            "routes/view-facs.html"
        else if ($template and $template = "introduction.html") then
            "routes/introduction.html"
        else
            "routes/view.html"
    return
        if (matches($exist:resource, "\.(png|jpg|jpeg|gif|tif|tiff|txt)$", "s")) then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
               <forward url="{$exist:controller}/data/{$path}{$id}"/>
           </dispatch>
        else if (ends-with($exist:resource, ".tex")) then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/modules/lib/latex.xql">
                    <add-parameter name="id" value="{$path}{$id}"/>
                </forward>
                <error-handler>
                    <forward url="{$exist:controller}/routes/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
            </dispatch>
        else if (ends-with($exist:resource, ".pdf")) then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/modules/lib/pdf.xql">
                    <add-parameter name="doc" value="{$path}{$id}"/>
                </forward>
                <error-handler>
                    <forward url="{$exist:controller}/routes/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
            </dispatch>
        else if ($mode = "plain") then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/modules/lib/transform.xql">
                    <add-parameter name="doc" value="{$path}{$id}"/>
                </forward>
                <error-handler>
                    <forward url="{$exist:controller}/routes/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
            </dispatch>
        else
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/{$html}"></forward>
                <view>
                    <forward url="{$exist:controller}/modules/view.xql">
                    {
                        if ($exist:resource != "toc.html") then
                            <add-parameter name="doc" value="{$path}{$id}"/>
                        else
                            ()
                    }
                        <set-header name="Cache-Control" value="no-cache"/>
                    </forward>
                </view>
                <error-handler>
                    <forward url="{$exist:controller}/routes/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
            </dispatch>

) ~:)
