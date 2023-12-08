xquery version "3.1";

module namespace nav="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/nav";

import module namespace templates = "http://exist-db.org/xquery/html-templating";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace console="http://exist-db.org/xquery/console";

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

declare %private function nav:create-lang-selector($lang as xs:string, $index as xs:integer) as element(a) {
    <a class="px-2.5 py-2 transition-colors duration-300 transform rounded-lg hover:text-ssrq-primary md:mx-2" href="{$entry?url}">
        <i18n:text key="{$entry?key}"/>
    </a>
};
