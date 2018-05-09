xquery version "3.1";

import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "modules/config.xqm";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $logout := request:get-parameter("logout", ());
declare variable $login := request:get-parameter("user", ());

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


if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>

else if (contains($exist:path, "/$shared/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/shared-resources/{substring-after($exist:path, '/$shared/')}"/>
    </dispatch>

else if (contains($exist:path, "/resources")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/resources/{substring-after($exist:path, '/resources/')}"/>
    </dispatch>

else if (contains($exist:path, "/transform")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/transform/{substring-after($exist:path, '/transform/')}"/>
    </dispatch>

else if (contains($exist:path, "/components")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/components/{substring-after($exist:path, '/components/')}"/>
    </dispatch>

else if (ends-with($exist:resource, ".xql")) then (
    login:set-user($config:login-domain, (), false()),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/{substring-after($exist:path, '/modules/')}"/>
        <cache-control cache="no"/>
    </dispatch>

) else if ($logout or $login) then (
    login:set-user($config:login-domain, (), false()),
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{replace(request:get-uri(), "^(.*)\?", "$1")}"/>
    </dispatch>

) else if (ends-with($exist:resource, ".html")) then (
    login:set-user($config:login-domain, (), false()),
    let $resource :=
        if (contains($exist:path, "/templates/")) then
            "templates/" || $exist:resource
        else
            $exist:resource
    return
        (: the html page is run through view.xql to expand templates :)
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}/{$resource}">
                <set-header name="Cache-Control" value="no-cache"/>
            </forward>
            <view>
                <forward url="{$exist:controller}/modules/view.xql"/>
            </view>
    		<error-handler>
    			<forward url="{$exist:controller}/error-page.html" method="get"/>
    			<forward url="{$exist:controller}/modules/view.xql"/>
    		</error-handler>
        </dispatch>

) else (
    login:set-user($config:login-domain, (), false()),
    (: let $id := replace(xmldb:decode($exist:resource), "^(.*)\..*$", "$1") :)
    let $id := xmldb:decode($exist:resource)
    let $path := substring-before($exist:path, $exist:resource)
    let $redir := local:resolve($path, $id)
    return
        if ($redir) then
            $redir
        else
    let $mode := request:get-parameter("mode", ())
    let $facsimiles := request:get-parameter("facs", ())
    let $html :=
        if ($exist:resource = "" and not(request:get-parameter("id", ()))) then
            "index.html"
        else if ($exist:resource = "doc-table.html") then
            "templates/doc-table.html"
        else if ($exist:resource = ("search.html", "toc.html")) then
            $exist:resource
        else if ($facsimiles) then
            "view-facs.html"
        else
            "view.html"
    return
        if (matches($exist:resource, "\.(png|jpg|jpeg|gif|tif|tiff|txt)$", "s")) then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
               <forward url="{$exist:controller}/data/{$path}{$id}"/>
           </dispatch>
        else if (ends-with($exist:resource, ".epub")) then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/modules/lib/get-epub.xql">
                    <add-parameter name="id" value="{$path}{$id}"/>
                </forward>
                <error-handler>
                    <forward url="{$exist:controller}/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
            </dispatch>
        else if (ends-with($exist:resource, ".tex")) then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/modules/lib/latex.xql">
                    <add-parameter name="id" value="{$path}{$id}"/>
                </forward>
                <error-handler>
                    <forward url="{$exist:controller}/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
            </dispatch>
        else if (ends-with($exist:resource, ".pdf")) then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/modules/lib/pdf.xql">
                    <add-parameter name="doc" value="{$path}{$id}"/>
                </forward>
                <error-handler>
                    <forward url="{$exist:controller}/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
            </dispatch>
        else if ($mode = "plain") then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/modules/lib/transform.xql">
                    <add-parameter name="doc" value="{$path}{$id}"/>
                </forward>
                <error-handler>
                    <forward url="{$exist:controller}/error-page.html" method="get"/>
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
                    <forward url="{$exist:controller}/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
            </dispatch>

)
