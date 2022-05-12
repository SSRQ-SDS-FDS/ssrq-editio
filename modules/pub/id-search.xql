xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
(:
declare option output:method "json";
declare option output:media-type "application/json";
:)

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common" at "../ext-common.xqm";

let $id := substring(request:get-parameter('id', ''), 1, 9)    (: ignore variants :)

let $search-results :=
    switch (substring($id, 1, 3))
        case 'lem'
        case 'key'
            return collection($config:data-root)/tei:TEI[descendant::tei:term/substring(data(@ref), 1, 9)=$id]
        case 'loc'
            return collection($config:data-root)/tei:TEI[descendant::tei:placeName/substring(data(@ref), 1, 9)=$id]
        case 'per'
            return collection($config:data-root)/tei:TEI[descendant::tei:persName/substring(data(@ref), 1, 9)=$id]
        case 'org'
            return collection($config:data-root)/tei:TEI[descendant::tei:orgName/substring(data(@ref), 1, 9)=$id]
        default
            return ()

return (
    <results>
        {for $result in $search-results
            let $idno := $result/tei:teiHeader/tei:fileDesc/tei:seriesStmt/tei:idno/text()
            let $key  := ec:format-id($idno)
            order by $idno
            return
                <result>
                    <idno>{$idno}</idno>
                    <citationKey>{$key}</citationKey>
                </result>
        }
    </results>
)
