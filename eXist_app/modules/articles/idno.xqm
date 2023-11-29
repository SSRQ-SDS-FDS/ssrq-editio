xquery version "3.1";

module namespace articles-idno="http://ssrq-sds-fds.ch/exist/apps/ssrq/articles/idno";

import module namespace errors="http://e-editiones.org/roaster/errors";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";

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
    if ($doc and paratext) then
        error($errors:SERVER_ERROR, "Either $doc or $paratext must be specified, not both.")
    else
        let $parts-joined := string-join(($prefix, $kanton, $volume, ($doc, $paratext)[1]), "-")
        let $doc-info := $config:static-docs-list-cache//volume/doc[ends-with(@xml:id, $parts-joined)]
        let $idno := if ($prefix) then
                $parts-joined
            else
                $doc-info/@xml:id/data(.)
        return
            map {
                "doc": $doc-info,
                "idno": $idno,
                "type": ($paratext[$paratext = $config:paratext-types], "article")[1]
            }
};

(:~
: Check if a IDNO is a case in the canton of Fribourg.
: Helper function, because FR cases require some special hadnling.
:
: @param $doc as element(doc) – The document-info to check.
: @return xs:boolean – True if the IDNO is a case in the canton of Fribourg, false otherwise.
:)
declare function articles-idno:is-case-in-fr($doc as element(doc)) as xs:boolean {
        $doc//kanton = 'FR' and $doc//case
};
