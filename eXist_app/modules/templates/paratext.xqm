xquery version "3.1";

module namespace paratext="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/paratext";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace html="http://ssrq-sds-fds.ch/exist/apps/ssrq/processing/html" at "../processing/html.xqm";
import module namespace i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/templates" at "../i18n/i18n-templates.xqm";
import module namespace i18n-settings="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/settings" at "../i18n/settings.xqm";
import module namespace idno-parser="http://ssrq-sds-fds.ch/exist/apps/ssrq/parser/idno" at "../parser/idno-parser.xqm";
import module namespace pxml="http://ssrq-sds-fds.ch/exist/apps/ssrq/processing/xml" at "../processing/xml.xqm";
import module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common" at "../ext-common.xqm";
import module namespace util="http://exist-db.org/xquery/util";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function paratext:page-title($node as node(), $model as map(*)) as element(h1) {
    <h1 class="title-1">
        {i18n:create-i18n-container($model?doc//special/text())}
        {' ' || idno-parser:print($model?idno)}
    </h1>
};

(:~
: Template for the table of contents
:
: @param $node The context node
: @param $model The model (passed by the template engine)
: @return The table of contents as elements h2 and ul
:)
declare function paratext:toc($node as node(), $model as map(*)) as element(nav) {
    (
        <nav class="mb-6 watch-with-top-button" role="list">
            <h2 class="title-2 mt-4">
                {i18n:create-i18n-container('toc')}
            </h2>
            {
                paratext:toc($model)
            }
        </nav>
    )
};

declare %private function paratext:toc($model as map(*)) as element(ul) {
    let $session-lang := i18n-settings:get-lang-from-model-or-config($model)
    return
        <ul class="list-disc ml-4 p-4" id="toc">
            {
                for $section in pxml:get-subsections($model?xml)
                return
                   paratext:toc-entry($section, $session-lang)
            }
        </ul>
};

declare %private function paratext:toc-entry($entry as element(), $session-lang as xs:string) {
    let $section-heading := $entry => ec:get-head()
    let $lang := if (not($entry/ancestor::tei:div[@type = 'section'][tei:div[@xml:lang = $session-lang]])) then 'de' else $session-lang
    return
    if ($section-heading/@type = ('title', 'subtitle')) then
        let $subsections := pxml:get-subsections($entry)
        let $output := ($section-heading/@n, $section-heading/text()) => string-join(' ')
        return
            <li class="ml-4">
                <a href="#{util:node-id($section-heading)}" class="toc-anchor text-blue-600 hover:underline cursor-pointer">{$output}</a>
                    {
                    if ($subsections and ($subsections//tei:head/@type = 'title' or $subsections//tei:head/@type = 'subtitle'))
                    then
                        <ul class="list-disc ml-4 px-4">
                            {
                            for $subsection in $subsections
                            return
                                paratext:toc-entry($subsection, $session-lang)
                            }
                        </ul>
                    else ()
                    }
            </li>[not($entry/@xml:lang) or $entry/@xml:lang = $lang and $entry/ancestor::tei:div[@type = 'section'][tei:div[@xml:lang = $lang]]]
    else ()
};

declare function paratext:render-content($node as node(), $model as map(*)) as element(section)+ {
    let $html-blocks := html:create-and-postprocess(pxml:get-text($model?xml), (), ())
    return
        (
            <section class="{$config:css-content-class}">
                {$html-blocks[1]}
            </section>,
            $html-blocks[2]
        )
};
