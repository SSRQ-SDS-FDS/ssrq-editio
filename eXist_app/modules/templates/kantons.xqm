xquery version "3.1";

module namespace kantons="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/kantons";

import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace util="http://exist-db.org/xquery/util";

import module namespace articles-list="http://ssrq-sds-fds.ch/exist/apps/ssrq/articles/list" at "../articles/list.xqm";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common" at "../ext-common.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xqm";
import module namespace ssrq-cache="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/cache" at "../repository/cache.xqm";

declare namespace i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/module";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
: Templating function, which will list all kantons
:
:
: @param $node node() - the current node (passed by the template engine)
: @param $model map(*) - the model (passed by the template engine)
: @return element() - the rendered HTML-fragment
:)
declare function kantons:list($node as node(), $model as map(*)) as element() {
    let $all-kantons := json-doc($config:app-root || '/resources/json/cantons.json')
    let $existing-kantons := ssrq-cache:load-from-static-cache-by-name($config:static-cache-path, $config:static-docs-list)/docs
    return
        element { node-name($node) } {
            $node/@* except $node/@data-template,
            for $kanton in map:keys($all-kantons)
            order by $all-kantons($kanton)?order
            return
                if ($kanton => contains('-'))
                then
                    kantons:render-merged($all-kantons($kanton), $kanton, $existing-kantons)
                else
                    kantons:render($all-kantons($kanton), $kanton, $existing-kantons)
        }
};

(:~
: Templating function, which will render combined kantons
:
: @param $kanton-info map(*) - the kanton-info
: @param $existing-kantons xs:string+ - the existing kantons
: @return element() - the rendered HTML-fragment
:)
declare %private function kantons:render-merged($kanton-info as map(*), $kanton as xs:string, $existing-kantons as element(docs)) as element(tr) {
    let $kanton-docs as element(kanton)? := id($kanton, $existing-kantons)
    let $kanton-parts :=  tokenize($kanton, '-')
    return
        <div class="kanton-card {if (exists($kanton-docs)) then 'has-docs' else 'inactive'}">
            {kantons:link-to-kanton(
                <div class="kanton-card_inner-container">
                    <div class="kanton-card_img-container">
                        {
                            kantons:badge($kanton-parts)
                        }
                    </div>
                    <div class="kanton-card_content">
                        <div class="kanton-card_content-heading">
                            <h4>{$kanton-parts => string-join('/')}</h4>
                            {kantons:docs-badge($kanton-docs)}
                        </div>
                        {kantons:render-department-title($kanton-info($kanton-parts[1]), $kanton)}
                    </div>
                </div>,
                $kanton, $kanton-docs)}
        </div>
};

(:~
: Templating function, which will render a single kanton
:
: @param $kanton-info map(*) - the kanton-info
: @param $kanton xs:string - the kanton
: @param $existing-kantons xs:string+ - the existing kantons
: @return element() - the rendered HTML-fragment
:)
declare %private function kantons:render($kanton-info as map(*), $kanton as xs:string, $existing-kantons as element(docs)) as element(div) {
    let $kanton-docs as element(kanton)? := id($kanton, $existing-kantons)
    return
        <div class="kanton-card {if (exists($kanton-docs)) then 'has-docs' else 'inactive'}">
            {kantons:link-to-kanton(
                <div class="kanton-card_inner-container">
                    <div class="kanton-card_img-container">
                        {kantons:badge($kanton)}
                    </div>
                    <div class="kanton-card_content">
                        <div class="kanton-card_content-heading">
                            <h4>{$kanton}</h4>
                            {kantons:docs-badge($kanton-docs)}
                        </div>
                        {kantons:render-department-title($kanton-info, $kanton)}
                    </div>
                </div>,
                $kanton, $kanton-docs)}
        </div>
};

declare %private function kantons:link-to-kanton($container as element(div), $name as xs:string, $kanton as element(kanton)?) as element() {
    if (exists($kanton)) then
        <a href="{ec:create-app-link(($name, ''))}">
            {$container}
        </a>
    else
        $container
};

(:~
: Templating function, which will render a kanton badge
:
: @param $kanton xs:string - the kanton
: @return element(img) - the rendered HTML-fragment
:)
declare %private function kantons:badge($kanton as xs:string+) as element(img)+ {
    for $x in $kanton
    return
        <img class="kanton-card_img" src="{concat('resources/images/kantone/', $x, '.svg')}" loading="lazy" alt="Badge {$x}" />
};

declare %private function kantons:docs-badge($kanton as element(kanton)?) as element(span)? {
    if (exists($kanton)) then
        <span>
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20
    20" fill="currentColor" class="w-3.5 h-3.5 me-0.5">
                            <path fill-rule="evenodd"
                                d="M4.5 2A1.5 1.5 0 003 3.5v13A1.5 1.5 0 004.5
    18h11a1.5 1.5 0 001.5-1.5V7.621a1.5 1.5 0 00-.44-1.06l-4.12-4.122A1.5 1.5 0
    0011.378 2H4.5zm2.25 8.5a.75.75 0 000 1.5h6.5a.75.75 0 000-1.5h-6.5zm0
    3a.75.75 0 000 1.5h6.5a.75.75 0 000-1.5h-6.5z"
                                clip-rule="evenodd"/>
                        </svg> {articles-list:count($kanton/volume)}
        </span>
    else
        ()
};

(:~
: Templating function, which will render a kanton department-title
:
: @param $kanton-info map(*) - the kanton-info
: @param $department xs:string - the department
: @param $existing-kantons xs:string+ - the existing kantons
: @return element(h3) - the rendered HTML-fragment
:)
declare %private function kantons:render-department-title($kanton-info as map(*), $department as xs:string) as element(h3) {
    let $title := $kanton-info?title($config:lang-settings?lang)
    let $department-html-title := util:parse-html(if ($title) then $title else $kanton-info?title("default"))/*/*[last()]/node()
    return
        <h3>
            {
                $department-html-title
            }
        </h3>
};
