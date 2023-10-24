xquery version "3.1";

module namespace articles-list="http://ssrq-sds-fds.ch/exist/apps/ssrq/articles/list";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace find="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/finder" at "../repository/finder.xqm";
import module namespace idno-parser="http://ssrq-sds-fds.ch/exist/apps/ssrq/idno/parser" at "../idno/parser.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $articles-list:ZH-order-helper as xs:string+ := ('NF_I_1_3', 'NF_I_1_11', 'NF_I_2_1', 'NF_II_3', 'NF_II_11');

declare function articles-list:by-kanton-and-volume() as element(docs) {
    articles-list:by-kanton-and-volume(find:regular-articles#0)
};

declare function articles-list:by-kanton-and-volume($loader-functions as (function() as element(tei:TEI)+)+) as element(docs) {
    <docs>
        {articles-list:kantons($loader-functions ! .())}
    </docs>
};

declare function articles-list:kantons($docs as element(tei:TEI)+) as element(kanton)+ {
    articles-list:kantons($docs, idno-parser:parse-regular#1)
};

declare function articles-list:kantons($docs as element(tei:TEI)+, $idno-parser as function(xs:string) as element(doc)) as element(kanton)+ {
    for $doc in $docs
    let $parsed-idno as element(doc) := $idno-parser($doc//tei:seriesStmt/tei:idno[not(@type)])
    group by $kanton := $parsed-idno//kanton
    order by $kanton
    return
        <kanton xml:id="{$kanton}">
            {articles-list:volumes($kanton, $parsed-idno)}
        </kanton>
};

declare function articles-list:volumes($kanton as xs:string, $docs as element(doc)+) as element(volume)+ {
    for $doc in $docs
    group by $volume := $doc//volume
    order by articles-list:get-volume-order-key($kanton, $volume)
    return
        <volume xml:id="{$kanton}-{$volume}">
            {
                articles-list:sort-docs($docs)
            }
        </volume>
};

declare function articles-list:get-volume-order-key($kanton as xs:string, $volume as xs:string) as xs:string {
    if ($kanton = 'ZH') then
        xs:string(index-of($articles-list:ZH-order-helper, $volume))
    else
        $volume
};

declare function articles-list:sort-docs($docs as element(doc)+) as element(doc)+ {
    let $cases := articles-list:count-volume-cases($docs)
    for $doc in $docs
    order by articles-list:get-doc-order-key($doc, $cases)
    return
        $doc
};

declare function articles-list:count-volume-cases($docs as element(doc)+) as xs:integer {
    distinct-values($docs/case) => count()
};

declare function articles-list:get-doc-order-key($doc as element(doc), $volume-cases as xs:integer) as xs:double {
    if ($doc/case) then
        (
            number($doc/doc)[$volume-cases eq 1],
            number($doc/case)
        )[1]
    else
        number($doc/doc)
};
