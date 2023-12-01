xquery version "3.1";

module namespace articles-idno="http://ssrq-sds-fds.ch/exist/apps/ssrq/articles/idno";

import module namespace errors="http://e-editiones.org/roaster/errors";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

(:~
: Construct a IDNO from it's fragments.
: Will throw an error if both $doc and $paratext are specified.
: @param $kanton as xs:string – The canton of the article.
: @param $volume as xs:string – The volume of the article.
: @param $doc as xs:string? – The document of the article.
: @param $paratext as xs:string? The paratext of the article.
: @return map(*) – A map containing the static document info, the IDNO and the type of the article.
:)
declare function articles-idno:construct($prefix as xs:string?,
                                         $kanton as xs:string,
                                         $volume as xs:string,
                                         $doc as xs:string?,
                                         $paratext as xs:string?) as map(*) {
    if ($doc and $paratext) then
        error($errors:SERVER_ERROR, "Either $doc or $paratext must be specified, not both.")
    else
        let $parts-joined := string-join(($prefix, $kanton, $volume, ($doc, $paratext)[1]), "-")
        let $doc-info := articles-idno:find-by-idno-in-docs($config:static-docs-list-cache/docs, $parts-joined, "-")
        let $idno := if ($prefix) then
                $parts-joined
            else
                $doc-info/@xml:id/data(.)
        return
            map {
                "doc": $doc-info,
                "idno": $idno,
                "type": if (exists($paratext) and $paratext[$paratext = $config:paratext-types]) then $paratext else "article"
            }
};

(:~
: Check if a IDNO is a case in the canton of Fribourg.
: Helper function, because FR cases require some special handling.
:
: @param $doc as element(doc) – The document-info to check.
: @return xs:boolean – True if the IDNO is a case in the canton of Fribourg, false otherwise.
:)
declare function articles-idno:is-case-in-fr($doc as element(doc)) as xs:boolean {
        $doc//kanton = 'FR' and $doc//case
};

(:
: Find an doc-info-element by the IDNO
: in the static docs-cache.
: This function includes some extra logic
: to handle FR cases – because the PDF-IDNOs
: are not matching the XML-IDNOs.
: Therefore, we create a ‚fuzzy‘ IDNO and
: try to match it. If there are multiple
: matches, we try to find the one with the
: lowest doc-number.
:
: @param $docs as element(docs) – The static docs-cache.
: @param $idno as xs:string – The IDNO to search for.
: @param $delimiter as xs:string – The delimiter, which seperates the idno-parts.
: @return element(doc) – The doc-info-element.
:)
declare %private function articles-idno:find-by-idno-in-docs($docs as element(docs), $idno as xs:string, $delimiter as xs:string) as element(doc) {
    let $doc := $docs//volume/doc[ends-with(@xml:id, $idno)]
    return
        if (exists($doc)) then
            $doc
        else
            let $fuzzy-idno := replace($idno, '(\d)+' || $delimiter || '(\d)+$', '$1(\\.\\d+)?' || $delimiter || '$2')
            let $matched := $docs//volume/doc[matches(@xml:id, $fuzzy-idno)]
            return
                if (count($matched) = 1) then
                    $matched
                else
                    (for $m in $matched order by $m/doc return $m)[1]
};
