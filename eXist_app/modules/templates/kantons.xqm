xquery version "3.1";

module namespace kantons="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/kantons";

import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace util="http://exist-db.org/xquery/util";

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
: @param $kanton xs:string - the kanton (passed by the template engine / the request)
: @return element() - the rendered HTML-fragment
:)
declare function kantons:list($node as node(), $model as map(*)) as element() {
    let $all-kantons := json-doc($config:app-root || '/resources/json/cantons.json')
    let $existing-kantons := ssrq-cache:load-from-static-cache-by-name($config:static-cache-path, $config:static-docs-list)//kanton/@xml:id/data(.)
    return
        element { node-name($node) } {
            for $kanton in map:keys($all-kantons)
            order by $all-kantons($kanton)?order
            return
                if ($kanton => contains('-'))
                then kantons:render-merged($all-kantons($kanton), $existing-kantons)
                else kantons:render($all-kantons($kanton), $kanton, $existing-kantons)
        }
};

(:~
: Templating function, which will render combined kantons
:
: @param $kanton-info map(*) - the kanton-info
: @param $existing-kantons xs:string+ - the existing kantons
: @return element() - the rendered HTML-fragment
:)
declare %private function kantons:render-merged($kanton-info as map(*), $existing-kantons as xs:string+) as element(tr) {
    let $kanton-parts :=  map:keys($kanton-info)
    return
    <tr>
        <td>
            {
                $kanton-parts[not(. = 'order')] ! kantons:badge(.)
            }
        </td>
        <td>
            {$kanton-parts[not(. = 'order')] => string-join('/')}
        </td>
        {kantons:render-department($kanton-info($kanton-parts[1]),$kanton-parts[1], $existing-kantons)}
    </tr>
};

(:~
: Templating function, which will render a single kanton
:
: @param $kanton-info map(*) - the kanton-info
: @param $kanton xs:string - the kanton
: @param $existing-kantons xs:string+ - the existing kantons
: @return element() - the rendered HTML-fragment
:)
declare %private function kantons:render($kanton-info as map(*), $kanton as xs:string, $existing-kantons as xs:string+) as element(tr) {
    <tr>
            <td>
                {kantons:badge($kanton)}
            </td>
            <td>{$kanton}</td>
        {kantons:render-department($kanton-info, $kanton, $existing-kantons)}
    </tr>
};

(:~
: Templating function, which will render a kanton badge
:
: @param $kanton xs:string - the kanton
: @return element(img) - the rendered HTML-fragment
:)
declare %private function kantons:badge($kanton as xs:string) as element(img) {
    <img src="{concat('resources/images/kantone/', $kanton, '.png')}" alt="{$kanton}" />
};

(:~
: Templating function, which will render a kanton department
:
: @param $kanton-info map(*) - the kanton-info
: @param $department xs:string - the department
: @param $existing-kantons xs:string+ - the existing kantons
: @return element() - the rendered HTML-fragment
:)
declare %private function kantons:render-department($kanton-info as map(*), $department as xs:string, $existing-kantons as xs:string+) as element(td) {
    let $department-html-title := util:parse-html($kanton-info?department)/*/*[last()]/node()
    return
        <td>
            {
                if ($department = $existing-kantons) then
                    <a href="{ec:create-app-link(($department, ''))}">
                        {$department-html-title}
                    </a>
                else
                    $department-html-title
            }
        </td>
};
