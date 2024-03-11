xquery version "3.1";

module namespace query="http://ssrq-sds-fds.ch/exist/apps/ssrq/query/query";

import module namespace ft="http://exist-db.org/xquery/lucene" at "java:org.exist.xquery.modules.lucene.LuceneModule";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace articles-idno="http://ssrq-sds-fds.ch/exist/apps/ssrq/articles/idno" at "../articles/idno.xqm";
import module namespace link="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/link" at "../repository/link.xqm";
import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "../utils.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function query:search() {
    (: not implemented :)
};

declare %private function query:search-articles($query as xs:string, $part as xs:string*) {};

declare function query:search-articles-text($docs as element(tei:TEI)+, $query as xs:string, $query-options as map(*)) as element()* {
    $docs//tei:body[*][ft:query(., $query, $query-options)] |
    $docs//tei:back[.//tei:orig[ft:query(., $query, $query-options  )]] |
    $docs//tei:body[*][.//tei:note//tei:orig[ft:query(., $query, $query-options )]]
};

declare function query:with-col($query, $options) {
    collection($config:data-root)/tei:TEI[not(@type)]//tei:body[*][ft:query(., $query, $options)] |
    collection($config:data-root)/tei:TEI[not(@type)]//tei:back[.//tei:orig[ft:query(., $query, $options)]] |
    collection($config:data-root)/tei:TEI[not(@type)]//tei:body[*][.//tei:note//tei:orig[ft:query(., $query, $options)]]
};

declare function query:articles-by-title-or-idno($articles as element(tei:TEI)+, $query as xs:string?) as element(tei:TEI)* {
    let $options := map:merge((
        query:create-options(true(), true()),
        map:entry('fields', ('has-facs', 'idno', 'origPlace-ref', 'title'))
    ))
    return
        $articles[ft:query(., query:build-field-query($query, ('title', 'idno'), 'OR'), $options)]
};

(: ~
: Controls how to generate options for the fulltext-search.
: See https://exist-db.org/exist/apps/doc/lucene#parameters for details.
:
: @param $allow-leading-wildcard as xs:boolean - Allow leading wildcard in search terms.
: @param $rewrite-filter as xs:boolean - Rewrite the query to use a filter instead of a query.
: @return element(options) - The options element, which can be used as the third argument of ft:query.
:)
declare %private function query:create-options($allow-leading-wildcard as xs:boolean, $rewrite-filter as xs:boolean) as map(*) {
    map {
        "leading-wildcard": query:convert-bool-to-lucene-value($allow-leading-wildcard),
        "filter-rewrite": query:convert-bool-to-lucene-value($rewrite-filter)
    }
};

(:~
: Lucene does not uses boolean, but strings
: with "yes" and "no" as values. This function
: will convert a boolean to the corresponding
: string.
:
: @param $value as xs:boolean - The boolean value to convert.
: @return xs:string - The string value.
:)
declare function query:convert-bool-to-lucene-value($value as xs:boolean) as xs:string {
    if ($value) then "yes" else "no"
};

(:
: Build a query string from a given query and a list of fields.
: Note: The returned query will only search in fields
:
: @param $query as xs:string? – The given query
: @param fields as xs:string+ – One or more fields to search in.
: @param $operand as xs:string – The operand to use between the fields.
: @return xs:string? – The query string.
:)
declare function query:build-field-query($query as xs:string?, $fields as xs:string+, $operand as xs:string) as xs:string? {
    if (exists($query) and $query[normalize-space()]) then
        ($fields ! string-join((., $query), ':'))
        => string-join(' ' || $operand  || ' ')
    else
        ()
};
