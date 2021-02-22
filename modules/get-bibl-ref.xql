xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "text";
declare option output:media-type "text/plain";

let $tab := '&#9;'
let $nl := '&#10;'

let $id := request:get-parameter("canton", "NE")

let $data-collection := '/db/apps/ssrq-data/data/' || $id

for $doc in collection($data-collection)/tei:TEI[descendant::tei:bibl/tei:ref]
    let $idno := $doc/tei:teiHeader/tei:fileDesc/tei:seriesStmt/tei:idno/text()
    for $ref in $doc//tei:bibl/tei:ref
    order by $idno
    return string-join(($idno, normalize-space(string-join($ref//text())), $ref/@target), $tab) || $nl
