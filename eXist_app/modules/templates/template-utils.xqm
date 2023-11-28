xquery version "3.1";

module namespace template-utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/utils";

import module namespace functx="http://www.functx.com";
import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace request="http://exist-db.org/xquery/request";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common" at "../ext-common.xqm";
import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "../utils.xqm";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

declare namespace xpath="http://www.w3.org/2005/xpath-functions";

(:~
: Utility templating function to display number of hits
: from the model (passed by the template engine) as a link.
:
: @param $node node() - the current node (passed by the template engine)
: @param $model map(*) - the model (passed by the template engine)
: @param $total-key xs:string - the key in the model to the total number of hits
: @param $link-base-params xs:string? - the base URL for the link, with parameters
: @return element(a) - the link
:)
declare
%templates:wrap
%templates:default("total-key", "total-documents")
function template-utils:display-hits($node as node(),
                                     $model as map(*),
                                     $total-key as xs:string,
                                     $link-base-params as xs:string?) as element(a) {
    let $link-base := if ($link-base-params) then tokenize($link-base-params, ';') ! $model?configuration?param-resolver(.) else ()
    return
    <a href="{ec:create-app-link($link-base, map{'per-page': $model($total-key)})}">{$model($total-key)}</a>
};

(:~
: Utility templating function to resolve links written like {app}/foo/bar
: in the template.
:
: @param $node node() - the current node (passed by the template engine)
: @param $model map(*) - the model (passed by the template engine)
: @return node() - the rendered node with resolved links
:)
declare function template-utils:resolve-links($node as node(), $model as map(*)) {
    template-utils:resolve-links-from-template(
        element { node-name($node) } {
            $node/@* except $node/@data-template,
            templates:process($node/node(), $model)
        }, $model
    )
};

(:~
: Utility templating function to resolve links written like {app}/foo/bar
: in the template.
:
: @param $nodes node()* - the current nodes (passed by the template engine)
: @param $model map(*) - the model (passed by the template engine)
: @return node()* - the rendered nodes with resolved links
:)
declare %private function template-utils:resolve-links-from-template($template as node()*, $model as map(*)) as node()* {
    for $node in $template
    return
        typeswitch($node)
            case element(a) | element(link) return
                if ($node/@href) then
                    element { node-name($node) } {
                        attribute href {
                            if ($node/@href => matches("^(?:[a-z-]+:)|#")) then
                                (: not a URL :)
                                $node/@href
                            else
                                template-utils:create-link(
                                    $node/@href,
                                    node-name($node) = xs:QName("a"),
                                    $model
                                )
                        },
                        $node/@* except $node/@href,
                        template-utils:resolve-links-from-template($node/node(), $model)
                    }
                else
                    element { node-name($node) } {
                        $node/@*,
                        template-utils:resolve-links-from-template($node/node(), $model)
                    }
            case element(form) return
                if ($node/@action) then
                    element { node-name($node) } {
                        attribute action { template-utils:create-link($node/@action, true(), $model) },
                        $node/@* except $node/@action,
                        template-utils:resolve-links-from-template($node/node(), $model)
                    }
                else
                    element { node-name($node) } {
                        $node/@*,
                        template-utils:resolve-links-from-template($node/node(), $model)
                    }
            case element(script) | element(img) return
                if ($node/@src) then
                    element { node-name($node) } {
                        attribute src { template-utils:create-link($node/@src, false(), $model) },
                        $node/@* except $node/@src
                    }
                else
                    element { node-name($node) } {
                        $node/@*,
                        template-utils:resolve-links-from-template($node/node(), $model)
                    }
            case element() return
                element { node-name($node) } {
                    $node/@*,
                    template-utils:resolve-links-from-template($node/node(), $model)
                }
            default return
                $node
};


(:~
: Utility templating function to create a internal link
: based on a link template.
:
: @param $input-value attribute() - the input value
: @param $add-lang-param xs:boolean - whether to add the lang parameter
: @param $model map(*) - the model (passed by the template engine)
: @return xs:string - the link
:)
 declare %private function template-utils:create-link($input-value as attribute(), $add-lang-param as xs:boolean, $model as map(*)) as xs:string {
        let $url := template-utils:create-url-base-for-link($input-value, $model)
        let $query-map := template-utils:create-query-map($url)
        return
            ec:create-link(
                functx:substring-before-if-contains($url, "?"),
                $query-map,
                $add-lang-param and starts-with($input-value, "{app}")
            )
 };

(:~
: Utility templating function to create a URL base for a link
:
: @param $input-value attribute() - the input value
: @param $model map(*) - the model (passed by the template engine)
: @return xs:string - the URL base
:)
declare function template-utils:create-url-base-for-link($input-value as attribute(), $model as map(*)) as xs:string {
    fold-left(template-utils:find-and-replace-parts-from-link-template($input-value), $input-value, function ($result, $current) {
                let $repl :=
                    switch ($current)
                    case 'app' return $config:base-url
                    case 'uri' return request:get-uri()
                    case 'qs' return "" || request:get-query-string()
                    default return
                        utils:coalexec(
                            function() { $model?configuration?param-resolver($current) },
                            function() { request:get-parameter($current, concat("{", $current, "}")) }
                        )
                return
                    replace($result, concat("\{", $current, "\}"), xs:string($repl))
        })
};

(:~
: Utility templating function to find and replace parts from a link template
:
: @param $input-value attribute() - the input value
: @return xs:string* - the template parts
:)
declare function template-utils:find-and-replace-parts-from-link-template($input-value as attribute()) as xs:string* {
    for $link-template-part in analyze-string($input-value, "\{[a-z-]+\}")/xpath:match
    group by $link-template-part
    return
        replace($link-template-part, "^\{(.*)\}$", "$1")
};

(:~
: Utility templating function to create a query map from a URL
:
: @param $url xs:string - the URL
: @return map(*) - the query map
:)
declare function template-utils:create-query-map($url as xs:string) as map(*) {
    ($url => substring-after("?") => tokenize("[&amp;;]")) ! (
                if (. = "") then
                    ()
                else if (. => contains("=")) then
                    map{substring-before(., "="): substring-after(., "=")}
                else
                    map{.:()}
    ) => map:merge()
};
