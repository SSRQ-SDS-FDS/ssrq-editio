xquery version "3.1";

module namespace xsl="http://ssrq-sds-fds.ch/exist/apps/ssrq/processing/xsl";

import module namespace transform="http://exist-db.org/xquery/transform";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "../utils.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $xsl:stylesheet-root := utils:path-concat(($config:app-root, 'resources', 'xsl'));

declare function xsl:apply($stylesheet as xs:string, $input as node()+, $params as map(*)?) as node()* {
    transform:transform(
        $input,
        xsl:load-stylesheet($stylesheet),
        xsl:create-parameters($params)
    )
};

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

declare %private function xsl:load-stylesheet($stylesheet as xs:string) as node() {
    doc(utils:path-concat(($xsl:stylesheet-root, $stylesheet)))
};
