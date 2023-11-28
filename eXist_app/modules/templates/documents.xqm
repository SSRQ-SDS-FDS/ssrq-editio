xquery version "3.1";

module namespace documents="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/documents";

import module namespace templates = "http://exist-db.org/xquery/html-templating";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common" at "../ext-common.xqm";
import module namespace find="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/finder" at "../repository/finder.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xqm";
import module namespace ssrq-cache="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/cache" at "../repository/cache.xqm";
import module namespace ssrq-helper="http://ssrq-sds-fds.ch/exist/apps/ssrq/helper" at "../ssrq-helper.xqm";


declare namespace i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/module";
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
%templates:wrap
%templates:default("start", 1)
%templates:default("per-page", 20)
function documents:list($node as node(),
                        $model as map(*),
                        $kanton as xs:string,
                        $volume as xs:string,
                        $start as xs:int,
                        $per-page as xs:int) as map(*) {
    let $documents := documents:load-and-group($kanton, $volume)
    return map {
        "current-page-documents": subsequence($documents, $start, $per-page),
        "total-documents": count($documents)
    }
};

declare %private function documents:load-and-group($kanton as xs:string, $volume as xs:string) as element(doc)+ {
    let $documents := ssrq-cache:load-from-static-cache-by-id($config:static-cache-path, $config:static-docs-list, string-join(($kanton,$volume), '-'))
    return
        (: $documents/doc[not(special) and not(opening) and num eq '1' and (not(case) or (case and doc eq '0'))] :)
        $documents/doc[not(special)][not(opening)][not(case)][num eq '1']
                            union $documents/doc[not(special)][not(opening)][case][doc eq '0'][num eq '1']
};
