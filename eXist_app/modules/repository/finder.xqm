xquery version "3.1";

module namespace find="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/finder";

import module namespace ft="http://exist-db.org/xquery/lucene" at "java:org.exist.xquery.modules.lucene.LuceneModule";
import module namespace util="http://exist-db.org/xquery/util";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace articles-idno="http://ssrq-sds-fds.ch/exist/apps/ssrq/articles/idno" at "../articles/idno.xqm";
import module namespace link="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/link" at "link.xqm";
import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "../utils.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";


(:~
: A function to find all TEI documents / regular articels in the data repository.
:
: @return a sequence of TEI documents
:)
declare function find:regular-articles() as element(tei:TEI)+ {
    collection($config:data-root)/tei:TEI[not(@type)][.//tei:seriesStmt/tei:idno[not(@type)]]
};

(:~
: A function to find all TEI documents / regular articels with an UUID in the data repository.
:
: @return a sequence of TEI documents
:)
declare function find:regular-articles-with-uuid() as element(tei:TEI)+ {
    collection($config:data-root)/tei:TEI[not(@type)][.//tei:seriesStmt/tei:idno[@type = 'uuid']]
};

(:~
: A function to find all TEI documents / paratextual documents in the data repository.
:
: @return a sequence of TEI documents
:)
declare function find:paratextual-documents() as element(tei:TEI)+ {
    collection($config:data-root)//tei:TEI[@type][.//tei:seriesStmt/tei:idno[not(@type)]]
};

(:~
: A function to find a specific paratextual document by its tei:idno.
:
: @param $idno the tei:idno of the document to find as xs:string
: @return the TEI document as element(tei:TEI)?
:)
declare function find:paratextual-document-by-idno($idno as xs:string) as element(tei:TEI)? {
    find:paratextual-document-by-idno($idno, $config:data-root)
};

(:~
: A function to find a specific paratextual document by its tei:idno.
:
: @param $idno the tei:idno of the document to find as xs:string
: @param $collection-path the path to the collection to search in as xs:string
: @return the TEI document as element(tei:TEI)?
:)
declare function find:paratextual-document-by-idno($idno as xs:string, $collection-path as xs:string) as element(tei:TEI)? {
    collection($config:data-root)//tei:TEI[@type][.//tei:seriesStmt/tei:idno[not(@type)][. = $idno]]
};

(:~
: A function to find a specific TEI document by its tei:idno.
:
: @param $idno the tei:idno of the document to find as xs:string
: @return the TEI document as element(tei:TEI)
:)
declare function find:article-by-idno($idno as xs:string) as element(tei:TEI)? {
    find:article-by-idno($idno, $config:data-root)
};

(:~
: A function to find a specific TEI document by its tei:idno.
:
: @param $idno the tei:idno of the document to find as xs:string
: @param $collection-path the path to the collection to search in as xs:string
: @return the TEI document as element(tei:TEI)
:)
declare function find:article-by-idno($idno as xs:string, $collection-path) as element(tei:TEI)? {
    collection($collection-path)/tei:TEI[not(@type)][.//tei:seriesStmt/tei:idno[. = $idno]]
};


(:~
: A function to find articles by the endings of their idno.
:
:
: @param $idno the ending of the idno of the document to find as xs:string
: @return the TEI document as element(tei:TEI)
:)
declare function find:article-by-idno-ending($idno as xs:string) as element(tei:TEI)? {
    (collection($config:data-root)/tei:TEI[not(@type)][.//tei:seriesStmt/tei:idno[ends-with(., $idno)]])[1]
};

(:~
: A function to find language catalogues based on $config:i18n-catalogues.
:
: @param $lang the language of the catalogue to find as xs:string
: @return the language catalogue as element(catalogue)
:)
declare function find:i18n-catalogue-by-lang($lang as xs:string) as element(catalogue)? {
    collection($config:i18n-catalogues)/catalogue[@xml:lang = $lang]
};


declare function find:pdf-by-idno($idno as xs:string, $doc as element(doc)) as map(*) {
    let $xml :=  utils:coalexec(function() { find:article-by-idno($idno)},
                                function() { find:paratextual-document-by-idno($idno) })
    return
        if (exists($xml)) then
            let $path := find:path-to-doc($xml)
            let $is-case-in-fr := articles-idno:is-case-in-fr($doc)
            let $filename := if ($is-case-in-fr) then
                                    replace($path?filename, '\.\d+', '')
                                else
                                    $path?filename
            let $pdf-path := utils:path-concat(($path?path, 'pdf', replace($filename, '\.xml$', '.pdf')))
            return
                map {
                    "available": util:binary-doc-available($pdf-path),
                    "filename": link:to-resource($doc, not($is-case-in-fr), '.pdf')
                }
        else
            map {
                "available": false(),
                "filename": ''
            }
};

(:~
: Find the path to a document,
: based on the document-uri of the root element.
:
: @param $doc the document to find as element()
: @return path information as map(*) with keys "filename", "path" and "uri"
:)
declare function find:path-to-doc($doc as element()) as map(*) {
    let $uri := $doc => root() => document-uri()
    let $uri-parts := tokenize($uri, '/')
    return
        map {
            "filename": $uri-parts[last()],
            "path": string-join($uri-parts[position() < last()], '/'),
            "uri": $uri
        }
};
