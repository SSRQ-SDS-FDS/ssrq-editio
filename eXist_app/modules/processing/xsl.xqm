xquery version "3.1";

module namespace xsl="http://ssrq-sds-fds.ch/exist/apps/ssrq/processing/xsl";

import module namespace transform="http://exist-db.org/xquery/transform";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "../utils.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $xsl:stylesheet-root := utils:path-concat(($config:app-root, 'resources', 'xsl'));

(:~
: Apply an XSLT stylesheet to one or more documents.
:
: @param $stylesheet as xs:string The path to the stylesheet to apply.
: @param $input as node()+ The document(s) to transform.
: @param $params as map(*)? The parameters to pass to the stylesheet.
: @return node()* The transformed document(s).
:)
declare function xsl:apply($stylesheet as xs:string, $input as node()+, $params as map(*)?) as node()* {
    transform:transform(
        $input,
        xsl:load-stylesheet($stylesheet),
        xsl:create-parameters($params)
    )
};

(:~
: Create a parameters element from a map.
:
: @param $params as map(*)? The parameters to pass to the stylesheet.
: @return element(parameters)? The parameters element.
:)
declare %private function xsl:create-parameters($params as map(*)?) as element(parameters)? {
    if (empty($params)) then
        ()
    else
        <parameters>
            {
                map:for-each($params, function($key, $value) {
                        <param name="{$key}" value="{$value}"/>
                    }
                )
            }
        </parameters>
};

(:~
: Load an XSLT stylesheet.
:
: @param $stylesheet as xs:string The path to the stylesheet to load.
: @return node() The loaded stylesheet.
:)
declare %private function xsl:load-stylesheet($stylesheet as xs:string) as node() {
    doc(utils:path-concat(($xsl:stylesheet-root, $stylesheet)))
};
