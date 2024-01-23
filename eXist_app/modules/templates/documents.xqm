xquery version "3.1";

module namespace documents="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/documents";

import module namespace ft="http://exist-db.org/xquery/lucene" at "java:org.exist.xquery.modules.lucene.LuceneModule";
import module namespace templates = "http://exist-db.org/xquery/html-templating";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace date-parser="http://ssrq-sds-fds.ch/exist/apps/ssrq/parser/date" at "../parser/date.xqm";
import module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common" at "../ext-common.xqm";
import module namespace find="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/finder" at "../repository/finder.xqm";
import module namespace i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/templates" at "../i18n/i18n-templates.xqm";
import module namespace i18n-settings="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/settings" at "../i18n/settings.xqm";
import module namespace link="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/link" at "../repository/link.xqm";
import module namespace pagination="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/pagination" at "pagination.xqm";
import module namespace query="http://ssrq-sds-fds.ch/exist/apps/ssrq/query/query" at "../query/query.xqm";
import module namespace ssrq-cache="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/cache" at "../repository/cache.xqm";
import module namespace template-utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/utils" at "template-utils.xqm";
import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "../utils.xqm";
import module namespace xsl="http://ssrq-sds-fds.ch/exist/apps/ssrq/processing/xsl" at "../processing/xsl.xqm";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
: Templating function, which will list
: all articles for a given volume
:
: @param $node node() - the current node (passed by the template engine)
: @param $model map(*) - the model (passed by the template engine)
: @param $kanton xs:string - the kanton (passed by the template engine / the request)
: @return map(*) - the model (passed to the template engine)
:)
declare
%templates:default("page", 1)
%templates:default("per-page", 20)
function documents:list($node as node(),
                        $model as map(*),
                        $kanton as xs:string,
                        $volume as xs:string,
                        $page as xs:int,
                        $per-page as xs:int,
                        $q as xs:string?) as element(section) {
    let $lang := i18n-settings:get-lang-from-model-or-config($model)
    let $volume-documents as element(tei:TEI)+ := find:articles-by-path(documents:construct-volume-path($kanton, $volume))
    let $documents-filtered as element(tei:TEI)* := query:articles-by-title-or-idno($volume-documents, $q)
    return
        <section class="documents relative" x-data="placesStdNames()" x-init="fetchAndInsert" data-lang="{$lang}" data-endpoint="{$config:base-url}/{$config:api-prefix}/{$config:api-version}/occurrences">
            {
                if (empty($documents-filtered)) then
                    documents:no-hits()
                else
                    let $documents-rendered := documents:title-cards($documents-filtered, $lang, $page, $per-page)
                    let $count := $documents-rendered?total
                    let $link-components := ($kanton, $volume, '')
                    let $link-params := if (exists($q)) then map {'q': $q, 'lang': $lang} else map {'lang': $lang}
                    let $pagination := pagination:calc-pages($count, $per-page, $page)
                                    => pagination:create-pages(
                                            $page,
                                            $link-components,
                                            $link-params
                                        )
                    let $hits-container :=  template-utils:display-hits($count, link:to-app($link-components, map:merge(($link-params, map{'per-page': $count }[$count > $per-page]))))
                    return
                        (
                            pagination:container('top', ($pagination, $hits-container)),
                            template-utils:loader-overlay(),
                            $documents-rendered?title-cards,
                            pagination:container('bottom', $pagination)
                        )
            }
        </section>
};



(:
: Output the documents as a list of short-titles.
: Uses information stored in the ft-index, which is returned
: by the ft-search. Can only be used on the results
: of a Lucene ft-search.
:)
declare %private function documents:title-cards($documents as element(tei:TEI)+, $lang as xs:string, $page as xs:integer, $per-page as xs:integer) as map(*) {
    let $ordered-documents := documents:reorder-hits-and-filter($documents)
    let $paginated-documents := pagination:get-subsequence($ordered-documents, $page, $per-page)
    return
        map {
            'title-cards': $paginated-documents?subset ! documents:render-card(., $lang),
            'total': $paginated-documents?total
        }
};

(:
: Reorder the hits by the sort-number field and filter out
: all documents, which are not marked as main.
:
: @param $documents element(tei:TEI)+ - the documents to reorder and filter
: @return element(tei:TEI)+ - the reordered and filtered documents
:)
declare function documents:reorder-hits-and-filter($documents as element(tei:TEI)+) as element(tei:TEI)+ {
    for $document in $documents
    where xs:boolean(ft:binary-field($document, 'main', 'xs:boolean')) (: see the eXist-db issue: https://github.com/eXist-db/exist/issues/5193 :)
    order by ft:binary-field($document, 'sort-number', 'xs:integer')
    return $document
};

declare %private function documents:render-card($document as element(tei:TEI), $lang as xs:string) as element() {
    xsl:apply(
        'document-info.xsl',
        $document,
        map {
            'formatted-date': date-parser:print(($document//tei:origDate[@type = 'document'])[1]),
            'has-facs': ft:binary-field($document, 'has-facs', 'xs:string'),
            'lang': $lang,
            'link': link:to-resource(
                ssrq-cache:load-from-static-cache-by-id($config:static-cache-path, $config:static-docs-list, ft:field($document, 'idno')),
                true(),
                '.html',
                map {'lang': $lang}
            ),
            'origPlace-ref': ft:binary-field($document, 'origPlace-ref', 'xs:string'),
            'printed-idno': ft:binary-field($document, 'printed-idno', 'xs:string')
        }
    )
};

declare %private function documents:construct-volume-path($kanton as xs:string, $volume as xs:string) {
    utils:path-concat(($config:data-root, $kanton, string-join(($kanton, $volume), '_')))
};


declare %private function documents:no-hits() as element() {
    <div class="w-full h-12 flex justify-center items-center my-4 rounded bg-ssrq-greyed-100">
        <h3>{i18n:create-i18n-container('no-hits-found')}</h3>
    </div>
};
