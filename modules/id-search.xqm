xquery version "3.1";

module namespace id-search="http://ssrq-sds-fds.ch/exist/apps/ssrq/id-search";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common" at "ext-common.xqm";
import module namespace doc-list="http://ssrq-sds-fds.ch/exist/apps/ssrq-data/doc-list" at "/db/apps/ssrq-data/modules/doc-list.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function id-search:search($id-param as xs:string?) as element(results) {
    let $id := substring($id-param, 1, 9)    (: ignore variants :)
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
    return
        <results>
            {
                for $result in $search-results
                let $idno := $result/tei:teiHeader/tei:fileDesc/tei:seriesStmt/tei:idno/text()
                let $key  := doc-list:get($idno) => ec:print-id()
                order by $idno
                return
                    <result>
                        <idno>{$idno}</idno>
                        <citationKey>{$key}</citationKey>
                    </result>
            }
        </results>
};
