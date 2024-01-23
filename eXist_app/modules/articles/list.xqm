xquery version "3.1";

module namespace articles-list="http://ssrq-sds-fds.ch/exist/apps/ssrq/articles/list";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace find="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/finder" at "../repository/finder.xqm";
import module namespace idno-parser="http://ssrq-sds-fds.ch/exist/apps/ssrq/parser/idno" at "../parser/idno.xqm";
import module namespace logger="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils/logger" at "../utils/logger.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $articles-list:ZH-order-helper as xs:string+ := ('NF_I_1_3', 'NF_I_1_11', 'NF_I_2_1', 'NF_II_3', 'NF_II_11');

(:~
: Returns a list of all articles grouped by kanton and volume.
:
: @return element(docs) - A list of all articles grouped by kanton and volume.
:)
declare function articles-list:by-kanton-and-volume() as element(docs) {
    articles-list:by-kanton-and-volume((find:regular-articles#0, find:paratextual-documents#0))
};

(:~
: Returns a list of all articles grouped by kanton and volume.
:
: @param $loader-functions as (function() as element(tei:TEI)+)+ - A list of functions that return a list of articles.
: @return element(docs) - A list of all articles grouped by kanton and volume.
:)
declare function articles-list:by-kanton-and-volume($loader-functions as (function() as element(tei:TEI)+)+) as element(docs) {
    <docs>
        {articles-list:kantons($loader-functions ! .())}
    </docs>
};

(:~
: Returns a list of all articles grouped by kanton.
:
: @param $docs as element(tei:TEI)+ - A list of articles.
: @return element(kanton)+ - A list of all articles grouped by kanton.
:)
declare function articles-list:kantons($docs as element(tei:TEI)+) as element(kanton)+ {
    articles-list:kantons($docs, idno-parser:parse-regular#1)
};

(:~
: Returns a list of all articles grouped by kanton.
:
: @param $docs as element(tei:TEI)+ - A list of articles.
: @param $idno-parser as function(xs:string) as element(doc) - A function that parses the idno of an article.
: @return element(kanton)+ - A list of all articles grouped by kanton.
:)
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

(:~
: Returns a list of all articles grouped by volume.
:
: @param $kanton as xs:string - The kanton of the articles.
: @param $docs as element(doc)+ - A list of articles.
: @return element(volume)+ - A list of all articles grouped by volume.
:)
declare function articles-list:volumes($kanton as xs:string, $docs as element(doc)+) as element(volume)+ {
    for $doc in $docs
    group by $volume := $doc//volume
    order by articles-list:get-volume-order-key($kanton, $volume)
    return
        <volume xml:id="{$kanton}-{$volume}" pdf="{articles-list:check-pdf($docs[1])}">
            {
                articles-list:sort-docs($doc)
            }
        </volume>
};

(:~
: Checks if a pdf file exists for an volume.
:
: @param $idno as element(doc)? - The idno of an article.
: @return xs:boolean - True if a pdf file exists for an volume, false otherwise.
:)
declare function articles-list:check-pdf($idno as element(doc)?) as xs:boolean  {
    try {
        let $dir := ($config:data-root, $idno/kanton, $idno/kanton || '_' || $idno/volume, 'pdf') => string-join('/')
        let $name := ($idno/prefix, $idno/kanton, $idno/volume) => string-join('-')
        return
            util:binary-doc-available($dir || '/' || $name || '.pdf')
    } catch * {
        (logger:log-and-raise-error($idno), false())[1]
    }
};

(:~
: Creates a key for sorting the volumes.
:
: @param $kanton as xs:string - The kanton of the articles.
: @param $volume as xs:string - The volume of the articles.
: @return xs:string - A key for sorting the volumes.
:)
declare function articles-list:get-volume-order-key($kanton as xs:string, $volume as xs:string) as xs:string {
    if ($kanton = 'ZH') then
        xs:string(index-of($articles-list:ZH-order-helper, $volume))
    else
        $volume
};

(:~
: Sorts a list of articles.
:
: @param $docs as element(doc)+ - A list of articles.
: @return element(doc)+ - A sorted list of articles.
:)
declare function articles-list:sort-docs($docs as element(doc)+) as element(doc)+ {
    let $cases := articles-list:count-volume-cases($docs)
    for $doc in $docs
    order by articles-list:get-doc-order-key($doc, $cases)
    return
        $doc
};

(:~
: Counts the number of cases in a volume.
:
: @param $docs as element(doc)+ - A list of articles.
: @return xs:integer - The number of cases in a volume.
:)
declare function articles-list:count-volume-cases($docs as element(doc)+) as xs:integer {
    distinct-values($docs/case) => count()
};

(:~
: Creates a key for sorting the articles.
:
: @param $doc as element(doc) - An article.
: @param $volume-cases as xs:integer - The number of cases in a volume.
: @return xs:double - A key for sorting the articles.
:)
declare function articles-list:get-doc-order-key($doc as element(doc), $volume-cases as xs:integer) as xs:double {
    if ($doc/case) then
        (
            number($doc/doc)[$volume-cases eq 1],
            number($doc/case)
        )[1]
    else
        number($doc/doc)
};

(:~
: Counts the documents in one or more volumes.
:
: @param $volume as element(volume)+ - A list of one or more volumes.
: @return xs:integer - The number of documents in the volumes (summed up).
:)
declare function articles-list:count($volumes as element(volume)+) as xs:integer {
    let $articles :=
        for $volume in $volumes
        for $d in $volume/doc[not(special)]
        group by $value := string-join($d/* except $d/num, '-')
        return $value
    return count($articles)
};
