xquery version "3.1";

module namespace toolbar="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/toolbar";

import module namespace i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/templates" at "../i18n/i18n-templates.xqm";

declare variable $toolbar:known-tools := map {
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
