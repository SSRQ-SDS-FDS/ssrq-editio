xquery version "3.1";

module namespace app="http://existsolutions.com/ssrq/app";

import module namespace templates="http://exist-db.org/xquery/templates";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "pm-config.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare
    %templates:wrap
function app:comment($node as node(), $model as map(*)) {
    let $back := root($model?data)//tei:back
    return
        $pm-config:web-transform($back, map { "root": $back }, $config:odd)
};

