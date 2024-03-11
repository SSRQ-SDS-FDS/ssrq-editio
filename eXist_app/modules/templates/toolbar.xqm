xquery version "3.1";

module namespace toolbar="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/toolbar";

import module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common" at "../ext-common.xqm";
import module namespace i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/templates" at "../i18n/i18n-templates.xqm";
import module namespace template-utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/utils" at "./template-utils.xqm";
import module namespace xsl="http://ssrq-sds-fds.ch/exist/apps/ssrq/processing/xsl" at "../processing/xsl.xqm";

declare variable $toolbar:known-tools := map {
    "cite": map {
        "function": toolbar:cite#1,
        "position": 2
    },
    "xml": map {
        "function": toolbar:xml#1,
        "position": 1
    }
};

(:~
: The toolbar container template.
:
: @param $node The node as node() – passed by the template engine.
: @param $model The model as map(*) – passed by the template engine.
: @param $tools The tools to display (as comma-separated string).
: @return The toolbar container as element(header).
:)
declare function toolbar:container($node as node(), $model as map(*), $tools as xs:string?) as element(header)? {
    if (empty($tools)) then
        ()
    else
        let $known-tools := toolbar:get-known-tools($tools, $toolbar:known-tools)
        return
            <header class="toolbar">
                {
                    for $tool in $known-tools
                    return $tool($model)
                }
            </header>[exists($known-tools)]
};

(:~
: Utility function to filter the provided tools by the known tools.
:
: @param $tools The tools to filter (as comma-separated string).
: @param $known-tools The known tools (as map).
: @return The known tools that are also in the provided tools (as map).
:)
declare function toolbar:get-known-tools($tools as xs:string, $known-tools as map(*)) as function(*)* {
    let $tool-names := tokenize($tools, ',') ! normalize-space(.)
    for $tool in $tool-names
    where map:contains($known-tools, $tool)
    order by $known-tools($tool)('position')
    return $known-tools($tool)('function')
};

(:~
: The XML tool / Download XML-button.
:
: @param $model The model (passed to the function).
: @return The XML tool as element(a)
:)
declare function toolbar:xml($model as map(*)) as element(a) {
    let $id := ($model?configuration?param-resolver('paratext'), $model?configuration?param-resolver('doc'))[1]
    return
    <a
        target="_blank"
        class="icon link-button"
        href="{{app}}/{{kanton}}/{{volume}}/{$id}.xml"
        title="i18n(view-tei)"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" d="M17.25 6.75 22.5 12l-5.25 5.25m-10.5 0L1.5 12l5.25-5.25m7.5-3-4.5 16.5" />
        </svg>
        <span class="description">
            {i18n:create-i18n-container('view-tei')}
        </span>
    </a>
};

(:~
: Creates a cite button / cite suggestion tooltip.
:
: @param $model The model (passed to the function).
: @return The cite button as element(details).
:)
declare function toolbar:cite($model as map(*)) as element(details) {
    let $icon := <svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
                    <path
                        fill="currentColor"
                        d="M11.192 15.757c0-.88-.23-1.618-.69-2.217c-.326-.412-.768-.683-1.327-.812c-.55-.128-1.07-.137-1.54-.028c-.16-.95.1-1.956.76-3.022c.66-1.065
                        1.515-1.867 2.558-2.403L9.372 5c-.8.396-1.56.898-2.26 1.505c-.71.607-1.34 1.305-1.9 2.094s-.98 1.68-1.25 2.69s-.345 2.04-.216 3.1c.168 1.4.62
                        2.52 1.356 3.35C5.837 18.58 6.754 19 7.85 19c.965 0 1.766-.29 2.4-.878c.628-.576.94-1.365.94-2.368zm9.124 0c0-.88-.23-1.618-.69-2.217c-.326-.42-.77-.692-1.327-.817c-.56-.124-1.073-.13-1.54-.022c-.16-.94.09-1.95.752-3.02c.66-1.06 1.513-1.86
                        2.556-2.4L18.49 5c-.8.396-1.555.898-2.26 1.505a11.29 11.29 0 0 0-1.894 2.094c-.556.79-.97 1.68-1.24 2.69a8.042 8.042 0 0 0-.217 3.1c.166 1.4.616 2.52 1.35 3.35c.733.834 1.647 1.252 2.743 1.252c.967 0 1.768-.29 2.402-.877c.627-.576.942-1.365.942-2.368z"/>
                 </svg>
    let $description := <span class="description">{i18n:create-i18n-container('cite-suggestion')}</span>
    let $title := xsl:apply('volume-title.xsl', $model?xml, ())
    return
        template-utils:tooltip-or-dropdown(
            ($icon, $description),
            ('icon', 'link-button'),
            (
                <h4 class="text-base mb-2">
                    {i18n:create-i18n-container('zitation')}
                </h4>,
                <p>
                    {$title//h3/text()}, {$title//p/node()};
                    <a class="weblink" href="{ec:create-p-link-from-id($model?idno)}">{$model?doc/@printed-idno/data(.)}</a>
                    ({i18n:create-i18n-container('accessed')} {' ' || format-dateTime(current-dateTime(), '[D01].[M01].[Y0001]')})
                </p>
            ),
            ("right-0", "left-auto", "min-w-60", "md:min-w-96"),
            false()
        )
};
