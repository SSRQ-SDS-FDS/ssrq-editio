xquery version "3.1";

module namespace nav="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/nav";

import module namespace templates = "http://exist-db.org/xquery/html-templating";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace path="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils/path" at "../utils/path.xqm";
import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "utils.xqm";
import module namespace idno-parser="http://ssrq-sds-fds.ch/exist/apps/ssrq/parser/idno" at "../parser/idno.xqm";

declare namespace i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/module";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $nav:links := (
    map {
        "key": "index",
        "url": $config:index-url,
        "target": "_blank"
    },
    map {
        'key': 'feedback',
        'url': 'mailto:info@ssrq-sds-fds.ch'
    }
);

declare function nav:menu-links($node as node(), $model as map(*)) as element(a)+ {
    for $link in $nav:links return nav:create-menu-link($link)
};

declare function nav:active-lang($node as node(), $model as map(*))  {
    for $display-lang at $index in $config:i18n-supported-languages-display
    where $config:i18n-supported-languages[$index] = $config:lang-settings?lang
    return
        element { node-name($node) } {
            $node/@* except $node/@data-template,
            $display-lang
        }
};

declare function nav:lang-selections($node as node(), $model as map(*)) as element(li)+ {
    for $display-lang at $index in $config:i18n-supported-languages-display
    let $lang-to-select := $config:i18n-supported-languages[$index]
    where $lang-to-select != $config:lang-settings?lang
    return
        <li>
            <a
              href="{concat('?{qs};lang=', $lang-to-select)}"
              class="block px-4 py-2 text-sm hover:text-ssrq-primary">
                {$display-lang}
            </a>
        </li>
};

(:~
: Templating function, which creates the parts
: for a breadcrumb navigation, based
: on the path-components of the current request.
:
: @param $node the node to be processed (passed by the templating engine)
: @param $model the model to be used (passed by the templating engine)
: @return the breadcrumbs navigation as a list of li elements
:)
declare function nav:breadcrumbs($node as node(), $model as map(*)) as element(li)+ {
    let $path-components := path:tokenize($model?configuration?param-resolver('request-path'))
    let $len-components := count($path-components)
    for $component at $index in $path-components
    return
        <li>
            {
                attribute aria-current {"page"}[$index = $len-components]
            }
            <div>
                <svg aria-hidden="true"
                    xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 6 10">
                    <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                            d="m1 9 4-4-4-4" />
                </svg>
                {
                    if ($index < $len-components) then
                        <a href="{nav:create-breadcrumb-link($path-components, $index)}">
                            <i18n:text key="{$component}">{nav:clean-breadcrumb-content($component)}</i18n:text>
                        </a>
                    else
                        <span>
                            <i18n:text key="{$component}">{nav:clean-breadcrumb-content($component)}</i18n:text>
                        </span>
                }
            </div>
        </li>
};

(:~
: Creates a href link based on a sequence of path components
: and an index (the current position of the breadcrumb).
:
: @param $path-components the path components as xs:string+
: @param $index the index of the current breadcrumb as xs:integer
: @return the link as xs:string
:)
declare function nav:create-breadcrumb-link($path-components as xs:string+, $index as xs:integer) as xs:string {
    utils:path-concat((
        $config:base-url,
        $path-components[position() <= $index]
    ))
};

(:~
: Creates a href link based on a entry with the following keys:
: - key: the key of the entry
: - url: the url of the entry
: - class: additional classes
:
: @param $entry the entry
: @return the link
:)
declare %private function nav:create-menu-link($entry as map(*)) as element(a) {
    <a class="menu-link" href="{$entry?url}">
        {
            if (exists($entry?target)) then
                attribute target {$entry?target}
            else
                ()
        }
        <i18n:text key="{$entry?key}"/>
    </a>
};

(:~
: Cleans the (displayed) content of a breadcrumb component
: by replacing dashes with spaces and removing
: the file extension.
:
: @param $content the content to be cleaned
: @return the cleaned content as xs:string
:)
declare %private function nav:clean-breadcrumb-content($content as xs:string) as xs:string {
    replace($content, '-', ' ')
    => replace('^(.*)\.\w+$', '$1')
    => idno-parser:print-volume()
    => replace('^((?:[A-Za-z0-9]+\.)*([0-9]+)) 1$', '$1')
};
