xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "text";
declare option output:media-type "text/plain";

import module namespace common="http://www.tei-c.org/tei-simple/xquery/functions/ssrq-common" at "ext-common.xql";

let $nl := '&#10;'

let $data-collection := '/db/apps/ssrq-data/data/SG'

for $header in collection($data-collection)/tei:TEI[descendant::tei:body/tei:div]/tei:teiHeader
    let $idno := $header/tei:fileDesc/tei:seriesStmt/tei:idno/text()
    let $key := common:format-id($header/tei:fileDesc/tei:seriesStmt/tei:idno/text())
    let $title := $header/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:head/text()
    let $keywords :=
        for $keyword in $header/tei:profileDesc/tei:textClass/tei:keywords/tei:term/@ref
            return '\term{' || data($keyword) || '}{}' || $nl
    order by $idno
    return ($key, $nl, $title, $nl, $keywords, $nl)
