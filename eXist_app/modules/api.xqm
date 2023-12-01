xquery version "3.1";

module namespace api="http://ssrq-sds-fds.ch/exist/apps/ssrq/api";

import module namespace errors = "http://e-editiones.org/roaster/errors";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace router="http://e-editiones.org/roaster/router";
import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace util="http://exist-db.org/xquery/util";

(:
 : The following modules provide functions which will be called by the
 : templating or used in the views.
 :)
import module namespace articles-idno="http://ssrq-sds-fds.ch/exist/apps/ssrq/articles/idno" at "articles/idno.xqm";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace find="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/finder" at "repository/finder.xqm";
import module namespace error="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/error" at "templates/error.xqm";
import module namespace occurrences-list="http://ssrq-sds-fds.ch/exist/apps/ssrq/occurrences/list" at "occurrences/list.xqm";
import module namespace tex="http://ssrq-sds-fds.ch/exist/apps/ssrq/processing/tex" at "processing/tex.xqm";
import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "utils.xqm";

(:~
: Handle API-calls concerning documents.
:
: @param $request as map(*) - The request map.
: @return item()? - The API response.
:)
declare function api:document-handler($request as map(*)) as item()? {
    if (not(map:contains($request?parameters, 'doc')) and not(map:contains($request?parameters, 'paratext'))) then
        error($errors:SERVER_ERROR, 'Missing doc or paratext parameter – cannot serve requested document')
    else
        switch (utils:extract-extension-from-path($request?path))
            case 'pdf'
                return api:serve-pdf($request, true())
            case 'tex'
                return api:serve-tex($request?parameters)
            case 'xml'
                return api:serve-xml($request?parameters)
            default
                return error($errors:SERVER_ERROR, 'Requested endpoint not found: ' || $request?path)
};

(:~
: Return information about occurences in the corpus.
:
: @param $request as map(*) - The request map.
: @return map(*) - A map of all occurences; splitted by entity-type.
:)
declare function api:occurrences-handler($request as map(*)) as map(*) {
    if (ends-with($request?path, '/occurrences')) then
        occurrences-list:all()
    else
        error($errors:SERVER_ERROR, 'Requested endpoint not found: ' || $request?path)
};

(:
: Stream a PDF file to the client.
: Also reused by views.xqm; can't be private.
:
: @param $request The request map
: @param $use-idno Whether to use the idno to find the pdf or not
: @return The rendered page
:)
declare function api:serve-pdf($request as map(*), $use-idno as xs:boolean)  as empty-sequence() {
    let $params := $request?parameters
    let $pdf :=
        if ($use-idno) then
            let $id := articles-idno:construct((), $params?kanton, $params?volume, $params?doc, $params?paratext)
            return
                find:pdf-by-idno($id?idno, $id?doc)
        else
            find:pdf-by-kanton-and-volume($params?kanton, $params?volume)
    return
        if ($pdf?available) then
                (
                    response:set-header('Content-Disposition', 'inline; filename="' || tokenize($pdf?real-path, '/')[last()] || '"'),
                    response:stream-binary(util:binary-doc($pdf?real-path), "application/pdf")
                )
        else
            error($errors:NOT_FOUND, 'Could not find pdf for: ' || $request?path)
};

(:~ Handling function, which serves the generated TeX
: for a given document.
:
: @param The request parameters
: @return The TeX for the document
:)
declare %private function api:serve-tex($params as map(*)) as xs:string {
    let $loaded-document := find:load-by-request-params([(), $params?kanton, $params?volume, $params?doc, $params?paratext])
    return
        if (exists($loaded-document?xml)) then
            tex:create($loaded-document?xml, ())
        else
            error($errors:NOT_FOUND, 'Could not load xml for: ' || $loaded-document?idno || ' and therefore not create TeX')
};

(:~
: Handling function, which serves the XML for a given document.
:
: @param $params The request parameters
: @return The XML for the document
: @throws 404 if the document does not exist
:)
declare %private function api:serve-xml($params as map(*)) as node() {
    let $loaded-document := find:load-by-request-params([(), $params?kanton, $params?volume, $params?doc, $params?paratext])
    return
        if (exists($loaded-document?xml)) then
            $loaded-document?xml
        else
            error($errors:NOT_FOUND, 'Could not load xml for: ' || $loaded-document?idno)
};
