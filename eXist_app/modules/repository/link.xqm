xquery version "3.1";

module namespace link="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/link";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common" at "../ext-common.xqm";

(:~
: Create a link to a resource
: based on the idno-doc-info-element
: Replaces: ssrq-helper:link-to-resource
:
: @param $doc as element(doc) – The document element.
: @param $use-doc as xs:boolean – Whether to use the child::doc element or not.
: @param $file-extension as xs:string – The file extension to use.
: @return xs:string – The link to the resource.
:)
declare function link:to-resource($doc as element(doc), $use-doc as xs:boolean, $file-extension as xs:string) as xs:string {
    link:to-resource($doc, $use-doc, $file-extension, ())
};

(:~
: Create a link to a resource
: based on the idno-doc-info-element
: Replaces: ssrq-helper:link-to-resource
:
: @param $doc as element(doc) – The document element.
: @param $use-doc as xs:boolean – Whether to use the child::doc element or not.
: @param $file-extension as xs:string – The file extension to use.
: @return xs:string – The link to the resource.
:)
declare function link:to-resource($doc as element(doc), $use-doc as xs:boolean, $file-extension as xs:string, $params as map(*)?) as xs:string {
    link:to-app((
        $doc/kanton,
        $doc/volume,
        (
            if ($doc/special) then
                $doc/special
            else
                concat(string-join(($doc/case, $doc/opening, $doc/doc[$use-doc]), '.'), '-', $doc/num)
        ) || $file-extension), $params)
};

(:~
: Create a link based on $config:base-url
: Replaces: ec:create-app-link
:
: @param $components as xs:string* – The components of the link.
: @param $params as map(*)? – The query string parameters.
: @return xs:string – The link.
:)
declare function link:to-app($components as xs:string*, $params as map(*)?) {
    link:create(($config:base-url, $components), $params)
};

(:~
: Create a link with a optional query string
:
: @param $components as xs:string* – The components of the link.
: @param $params as map(*)? – The query string parameters.
: @return xs:string – The link.
:)
declare function link:create($components as xs:string*, $params as map(*)?) {
    let $host := string-join($components, '/')
    let $params := link:build-query-string($params)
    return
        if ($host => ends-with('/')) then
            concat($host, $params)
        else
            concat($host, '/', $params)
};

(:~
: Create a query string from a map
:
: @param $params as map(*)? – The query string parameters.
: @return xs:string – The query string. Empty if $params is empty.
:)
declare function link:build-query-string($params as map(*)?) as xs:string? {
    if (empty($params) or count(map:keys($params)) = 0) then
        ()
    else
        concat('?',
            map:for-each($params, function ($key, $value) {
               ($key, $value) => string-join('=')
           })
            => string-join('&amp;')
        )
};
