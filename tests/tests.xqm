xquery version "3.1";

(:~~
: This module contains function to proceed various tests
:
: @author Bastian Politycki, SSRQ
: @date 16.02.2022
:
: every function needs to return a map with the following keys: 'name', 'description', 'exp', 'result'
:
:)

module namespace tests="https://www.ssrq-sds-fds.ch/tests";

import module namespace app="http://existsolutions.com/ssrq/app" at "../modules/ssrq.xql";
import module namespace test-utils="https://www.ssrq-sds-fds.ch/test-utilts" at "test-utils.xqm";
import module namespace query="http://existsolutions.com/ssrq/search" at "../modules/ssrq-search.xql";
import module namespace request ="http://exist-db.org/xquery/request";
import module namespace ssrq-utils="http://existsolutions.com/ssrq/utils" at "../modules/ssrq-util.xqm";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../modules/config.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $tests:host := 'http://localhost:' || request:get-server-port() || '/exist/apps/ssrq';

declare function tests:find-document() as map(*)*{
    for $id in ('SSRQ_FR_I_2_8_0001', 'SSRQ_FR_I_2_8_0002_000', 'SSRQ_SG_III_4_015_1')
    return
        map {
            "name": "find-document()",
            "description": "Check if " || $id || " is loaded and tei:body found.",
            "exp": true(),
            "result": let $data := app:load(<div/>, map{}, $id, (), $id, ())
                        return
                        if (exists($data?data) and $data?data => name() = 'body' )
                        then true()
                        else false()
        }
};

declare function tests:edition-text() as map(*)* {
    for $id in ('/FR/SSRQ_FR_I_2_8_0001.xml', '/FR/SSRQ_FR_I_2_8_0002_000.xml', '/SG/SSRQ_SG_III_4_015_1.xml')
    return
        map {
            "name": "edition-text()",
            "description": "Check if the rendering of the edition text is correct for " || tokenize($id, '/')[last()],
            "exp": true(),
            "result": let $data := test-utils:fetch-get($tests:host || $id)
                        return
                            if ($data//*[@id = 'document-pane']//*[@class = 'tei-body5'] and not($data//*[@id = 'document-pane']//*[contains(./@class, 'tei-back')]))
                            then true()
                            else false()
        }
};

declare function tests:non-existent-search-terms() as map(*)* {
    for $term in ('Borussia Dortmund', 'Coronapandemie', 'Softwareentwicklung')
    return
        map {
            "name": "tests:non-existent-search-terms()",
            "description": "Test if there is no search result for " || $term,
            "exp": 0,
            "result": let $search := query:query-texts('', $term)
                        return $search?hits => count()
        }
};

declare function tests:existing-search-terms() as map(*)* {
    for $term in ('Hexe', 'Gericht', 'Richter')
    return
        map {
            "name": "tests:existing-search-terms()",
            "description": "Test if there are search results for " || $term,
            "exp": true(),
            "result": let $search := query:query-texts('', $term)
                        return $search?hits => count() > 0
        }
};

declare function tests:count-docs() as map(*)* {
    for $canton in xmldb:get-child-collections($config:data-root)[not(. = 'temp') and not(. = 'misc')]
    return
        map {
        "name": "tests:count-docs()",
        "description": "Count docs for " || $canton,
        "exp": true(),
        "result":
            try {
                sum(for $volume in xmldb:get-child-collections(($config:data-root, $canton) => string-join('/'))
                return
                    ssrq-utils:countDocs(($config:data-root, $canton, $volume) => string-join('/'), $volume))
                > 0
            } catch * {
                error(xs:QName($err:code), $err:description)
            }
        }
};
