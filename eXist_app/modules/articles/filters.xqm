xquery version "3.1";

module namespace articles-filters="http://ssrq-sds-fds.ch/exist/apps/ssrq/articles/filters";

import module namespace functx="http://www.functx.com";
import module namespace date-parser="http://ssrq-sds-fds.ch/exist/apps/ssrq/parser/date" at "../parser/date.xqm";
import module namespace find="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/finder" at "../repository/finder.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $articles-filters:correction-list as map(xs:string, xs:string) := map {
        "Burgarchiv": "Burgarchiv Grabs",
        "Germanisches": "Germanisches Nationalmuseum Nürnberg",
        "Fürstlich": "Fürstlich Fürstenbergisches Archiv Donaueschingen",
        "KKGA Gams": "KKGA"
};


(:~
: A function which returns values for filtering the documents
: by publication-date, creation-date (period) and archive.
: Uses find:regular-articles#0 as the default loader-function.
:
: @return an element containing the filters as elements(filters)
:)
declare function articles-filters:create() as element(filters) {
    articles-filters:create(find:regular-articles#0)
};

(:~
: A function which returns values for filtering the documents
: by publication-date, creation-date (period) and archive.
:
: @param $loader-functions as (function() as element(tei:TEI)+)+ - A list of functions that return a list of articles.
: @return an element containing the filters as elements(filters)
:)
declare function articles-filters:create($loader-functions as (function() as element(tei:TEI)+)+) as element(filters) {
    let $docs := $loader-functions ! .()
    return
    <filters>
        {
            (
                articles-filters:create-pubdate-range($docs),
                articles-filters:create-period-range($docs),
                articles-filters:create-archive-list($docs)
            )
        }
    </filters>
};

(:~
: A function which returns the minimum and maximum publication-year of the documents
:
: @param $docs The documents to be filtered as element(tei:TEI)+
: @return an element containing the filters as elements(pubdate-range)
:)
declare function articles-filters:create-pubdate-range($docs as element(tei:TEI)+) as element(pubdate-range) {
    <pubdate-range>
        {
            let $pubdate-range := articles-filters:get-min-max-pubdate($docs)
            return (
                <min>{$pubdate-range?min}</min>,
                <max>{$pubdate-range?max}</max>
            )
        }
    </pubdate-range>
};

declare function articles-filters:get-min-max-pubdate($docs as element(tei:TEI)+) as map(xs:string, xs:anyAtomicType) {
    let $dates as xs:integer* :=
        $docs//tei:teiHeader//tei:publicationStmt/tei:date[@type='electronic']/@when-custom ! date-parser:extract-year(.)
    return
        map {
            "min": min($dates),
            "max": max($dates)
        }
};

(:~
: A function which returns the minimum and maximum year of the documents
:
: @param $docs The documents to be filtered as element(tei:TEI)+
: @return an element containing the filters as elements(period-range)
:)
declare function articles-filters:create-period-range($docs as element(tei:TEI)+) as element(period-range) {
    <period-range>
        {
            let $period-range := articles-filters:get-min-max-period($docs)
            return (
                <min>{$period-range?min}</min>,
                <max>{$period-range?max}</max>
            )
        }
    </period-range>
};

declare function articles-filters:get-min-max-period($docs as element(tei:TEI)+) as map(xs:string, xs:anyAtomicType) {
    let $dates as xs:integer* :=
        $docs//tei:teiHeader//tei:history/tei:origin/tei:origDate/@when-custom ! date-parser:extract-year(.)
    return
        map {
            "min": min($dates),
            "max": max($dates)
        }
};

(:~
: A function which returns a list of archives with their corrected names
: Uses the default correction-list defined in the module.
:
: @param $docs The documents to be filtered as element(tei:TEI)+
: @return an element containing the filters as elements(archives)
:)
declare function articles-filters:create-archive-list($docs as element(tei:TEI)+) as element(archives) {
    articles-filters:create-archive-list($docs, $articles-filters:correction-list)
};

(:~
: A function which returns a list of archives with their corrected names
:
: @param $docs The documents to be filtered as element(tei:TEI)+
: @param $correction-list A map of archive-ids and their corrected names
: @return an element containing the filters as elements(archives)
:)
declare function articles-filters:create-archive-list($docs as element(tei:TEI)+, $correction-list as map(xs:string, xs:string)) as element(archives) {
    <archives>
        {
            for $archive in $docs//tei:teiHeader//tei:msDesc/tei:msIdentifier/tei:idno[articles-filters:check-archive-idno(.)]
            let $archive-id := articles-filters:convert-archive-idno($archive)
            let $archive-title := articles-filters:get-archive-title($archive-id, $correction-list)
            where $archive-title != "Fehlt"
            group by $archive-title
            order by $archive-title
            return
                <archive>{$archive-title}</archive>
        }
    </archives>
};

declare %private function articles-filters:check-archive-idno($idno as element(tei:idno)) as xs:boolean {
    exists($idno[(@xml:lang = 'de', count(./preceding-sibling::tei:idno) = 0)][./text()[1] => string-length() > 0])
};

declare %private function articles-filters:convert-archive-idno($idno as xs:string) as xs:string {
    $idno
    => replace("^\s*(\w+).*$", "$1")
    => functx:substring-before-if-contains(',')
};

declare %private function articles-filters:get-archive-title($archive-id as xs:string, $correction-list as map(xs:string, xs:string)) as xs:string {
    ($correction-list($archive-id), $archive-id)[1]
};
