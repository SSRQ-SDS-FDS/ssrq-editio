xquery version "3.1";

module namespace template-utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/utils";

import module namespace errors = "http://e-editiones.org/roaster/errors";
import module namespace functx="http://www.functx.com";
import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace request="http://exist-db.org/xquery/request";

import module namespace articles-idno="http://ssrq-sds-fds.ch/exist/apps/ssrq/articles/idno" at "../articles/idno.xqm";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common" at "../ext-common.xqm";
import module namespace find="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/finder" at "../repository/finder.xqm";
import module namespace i18n-settings="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/settings" at "../i18n/settings.xqm";
import module namespace i18n = 'http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/module' at '../i18n/i18n.xqm';
import module namespace i18n-templates="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/templates" at "../i18n/i18n-templates.xqm";
import module namespace link="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/link" at "../repository/link.xqm";
import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "../utils.xqm";
import module namespace app="http://ssrq-sds-fds.ch/exist/apps/ssrq/app" at "../ssrq.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xpath="http://www.w3.org/2005/xpath-functions";

(:
: Utility templating function to create an attribute
: data-app with the base URL on the root element and
: apply the i18n-translation on it's children. Therefore it
: will at first process all templates on the children and
: then apply the i18n-translation.
:
: @param $node node() - the current node (passed by the template engine)
: @param $model map(*) - the model (passed by the template engine)
: @return element(html) - the root element with the attribute
:)
declare function template-utils:create-root-and-translate($node as node(), $model as map(*)) as element(html) {
    let $lang := i18n-settings:get-lang-from-model-or-config($model)
    return
        <html lang="{$lang}" data-app="{$config:base-url}">
            {
                $node/@* except $node/@data-template,
                i18n:process-with-xsl(
                    templates:process($node/*, $model),
                    $lang,
                    ()
                )
            }
        </html>
};

(:
: Prints the title from the model –
: and uses the param-resolver to resolve the values;
: the titles are translated using the i18n module
: If a translation is not found, the title is printed as given.
: Nothing is returned if no title is found.
:
: @param $node node() - the current node (passed by the template engine)
: @param $model map(*) - the model (passed by the template engine)
: @return element() - the title
:)
declare function template-utils:print-title($node as node(), $model as map(*)) as element()? {
    element { node-name($node) } {
        $node/@* except $node/@data-template,
        (
            for $title-key at $i in ('maintitle', 'subtitle')
            let $title-part := $model?configuration?param-resolver($title-key)
            where exists($title-part)
            return
                element { 'h' || $i } {
                    attribute class { if ($i = 1) then 'title-1' else 'title-2' },
                    if ($title-part instance of xs:string) then
                        <i18n:text key="{$title-part}">{$title-part}</i18n:text>
                    else
                        $title-part
                }
        )
    }[*]
};

declare function template-utils:load-by-idno($node as node(),
                                             $model as map(*),
                                             $kanton as xs:string,
                                             $volume as xs:string,
                                             $doc as xs:string?,
                                             $paratext as xs:string?,
                                             $odd as xs:string?) as map(*) {
    let $loaded-document := find:load-by-request-params([(), $kanton, $volume, $doc, $paratext])
    let $has-facs := exists($loaded-document?xml//tei:pb[@facs]) and not($odd eq $config:odd-normalized)
    return
        map {
            "idno": $loaded-document?idno,
            "doc": $loaded-document?doc,
            "xml": utils:coalesce($loaded-document?xml, app:failed-to-load($loaded-document?idno)), (: deprecated :)
            "config": map {
                "odd": utils:coalesce($odd, $config:odd),
                "view": app:query-view($loaded-document?xml/tei:text, $config:default-view)
            },
            "body-class": if ($has-facs) then 'col-md-6' else 'col-md-10',
            "has-facs": xs:string($has-facs)
        }
};

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
declare function template-utils:display-hits($hits as xs:integer, $link as xs:string) as element(a) {
    <a href="{$link}">
        <span class="text-ssrq-primary mr-1">
            {$hits}
        </span>
            {i18n-templates:create-i18n-container(if ($hits = 1) then 'found-single' else 'found')}
    </a>
};

(:~
: Templating function, which will create PDF-download-links
: if the PDF is available.
:
: @param $node node() - the current node (passed by the template engine)
: @param $model map(*) - the model (passed by the template engine)
: @return element(a) - the link if the PDF is available, otherwise nothing
:)
declare function template-utils:display-pdf-download($node as node(), $model as map(*)) as element(a)? {
    let $pdf := find:pdf-by-idno($model?idno, $model?doc)
    return
        if ($pdf?available) then
            <a href="{$pdf?filename}">
                {
                    $node/@* except $node/@data-template,
                    templates:process($node/node(), $model)
                }
            </a>
        else ()
};

(: Render a badge
: with a document symbol and a simple counter
:
: @param $count xs:integer - the counter
: @return element(span) - the rendered badge
:)
declare function template-utils:counter-badge($count as xs:integer) as element(span) {
    <span>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20
    20" fill="currentColor" class="w-3.5 h-3.5 mr-0.5">
                            <path fill-rule="evenodd"
                                d="M4.5 2A1.5 1.5 0 003 3.5v13A1.5 1.5 0 004.5
    18h11a1.5 1.5 0 001.5-1.5V7.621a1.5 1.5 0 00-.44-1.06l-4.12-4.122A1.5 1.5 0
    0011.378 2H4.5zm2.25 8.5a.75.75 0 000 1.5h6.5a.75.75 0 000-1.5h-6.5zm0
    3a.75.75 0 000 1.5h6.5a.75.75 0 000-1.5h-6.5z"
                                clip-rule="evenodd"/>
                        </svg> {$count}
    </span>
};

(:~~
: Utility Function to insert the
: app-title as an alt-Attribute into html:img
:
: @param $node node() - the current node (passed by the template engine)
: @param $model map(*) - the model (passed by the template engine)
: @return attribute(alt) - the alt-Attribute
:)
declare %templates:wrap function template-utils:insert-alt($node as node(), $model as map(*)) as attribute(alt) {
    let $lang := i18n-settings:get-lang-from-model-or-config($model)
    return
        attribute alt {
            $config:app-titles($lang)
        }
};

(:~
: Utility templating function to resolve links written like {app}/foo/bar
: in the template.
:
: @param $node node() - the current node (passed by the template engine)
: @param $model map(*) - the model (passed by the template engine)
: @return node() - the rendered node with resolved links
:)
declare function template-utils:resolve-links($node as node(), $model as map(*), $add-lang-param as xs:boolean?) {
    template-utils:resolve-links-from-template(
        element { node-name($node) } {
            $node/@* except ($node/@data-template | $node/@data-template-add-lang-param),
            templates:process($node/node(), $model)
        }, $model, $add-lang-param
    )
};

declare function template-utils:loader-overlay() as element(div) {
    <div class="absolute bg-white bg-opacity-60 z-10 h-full w-full flex items-start" id="loading-overlay">
    <div class="flex items-center justify-center">
      <span class="text-3xl mr-4">{i18n-templates:create-i18n-container('loading')}</span>
      <svg class="animate-spin h-5 w-5 text-ssrq-primary" xmlns="http://www.w3.org/2000/svg" fill="none"
        viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor"
          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
        </path>
      </svg>
    </div>
  </div>
};

(:~
: Utility templating function to resolve links written like {app}/foo/bar
: in the template.
:
: @param $nodes node()* - the current nodes (passed by the template engine)
: @param $model map(*) - the model (passed by the template engine)
: @return node()* - the rendered nodes with resolved links
:)
declare %private function template-utils:resolve-links-from-template($template as node()*, $model as map(*), $add-lang-param as xs:boolean?) as node()* {
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
                                    ($add-lang-param, node-name($node) = xs:QName("a"))[1],
                                    $model
                                )
                        },
                        $node/@* except $node/@href,
                        template-utils:resolve-links-from-template($node/node(), $model, $add-lang-param)
                    }
                else
                    element { node-name($node) } {
                        $node/@*,
                        template-utils:resolve-links-from-template($node/node(), $model, $add-lang-param)
                    }
            case element(form) return
                if ($node/@action) then
                    element { node-name($node) } {
                        attribute action { template-utils:create-link($node/@action, true(), $model) },
                        $node/@* except $node/@action,
                        template-utils:resolve-links-from-template($node/node(), $model, $add-lang-param)
                    }
                else
                    element { node-name($node) } {
                        $node/@*,
                        template-utils:resolve-links-from-template($node/node(), $model, $add-lang-param)
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
                        template-utils:resolve-links-from-template($node/node(), $model, $add-lang-param)
                    }
            case element(input) return
                if ($node/@hx-get) then
                    element { node-name($node) } {
                        attribute hx-get { template-utils:create-link($node/@hx-get, false(), $model) },
                        $node/@* except $node/@hx-get
                    }
                else
                    element { node-name($node) } {
                        $node/@*,
                        template-utils:resolve-links-from-template($node/node(), $model, $add-lang-param)
                    }
            case element() return
                element { node-name($node) } {
                        $node/@*,
                        template-utils:resolve-links-from-template($node/node(), $model, $add-lang-param)
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
        let $path := functx:substring-before-if-contains($url, "?")
        return
            link:create(
                $path[string-length(.) > 0],
                if (
                    $add-lang-param
                    and starts-with($input-value, "{app}")
                    and not(map:contains($query-map, 'lang'))
                ) then
                    $query-map => map:put("lang", $config:lang-settings?lang)
                else
                    $query-map
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
                    case 'qs'  return "" || request:get-query-string()
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
