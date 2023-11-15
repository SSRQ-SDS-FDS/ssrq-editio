xquery version "3.1";

module namespace find="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/finder";

import module namespace ft="http://exist-db.org/xquery/lucene" at "java:org.exist.xquery.modules.lucene.LuceneModule";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";

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
