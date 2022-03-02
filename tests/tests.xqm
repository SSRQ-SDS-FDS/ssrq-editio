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
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../modules/pm-config.xql";
import module namespace cache="http://exist-db.org/xquery/cache";
import module namespace doc-list="http:///www.ssrq-sds-fds.ch/ssrq-data/doc-list" at "/db/apps/ssrq-data/modules/doc-list.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $tests:host := substring-before(request:get-url(), '/exist') || '/exist/apps/ssrq';


(:~ *********************
: Tests to check general functionality
:
:
: ***********************
:)

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
    let $exp := (259, 208)
    for $volume at $i in ('SG_III_4', 'FR_I_2_8')
    return
        map {
            "name": "tests:count-docs()",
            "description": "Test if the number of docs in docs.xml is correct",
            "exp": $exp[$i],
            "result": doc-list:get($volume) => count()
        }
};

declare function tests:cache-handling() as map(*)* {
    for $fragment in ('/?kanton=SG', '/?kanton=SG&amp;volume=SG_III_4&amp;start=41', '/NE/SDS_NE_3_002.xml?odd=ssrq.odd&amp;view=body')
    let $destroy := cache:destroy('ssrq-cache')
    return
        map {
            "name": "tests:cache-handling()",
            "description": "Test if caching implementation is working for " || $fragment,
            "exp": "element()",
            "result":
                        let $request := test-utils:fetch-get($tests:host || $fragment)
                        let $key := cache:keys('ssrq-cache')[1]
                        return
                            cache:get('ssrq-cache', $key) => util:get-sequence-type()
            }

};

(:~ *********************
: Tests to check TEI rendering
:
:
: ***********************
:)

declare function tests:edition-text() as map(*)* {
    for $id in ('/FR/SSRQ_FR_I_2_8_0001.xml', '/FR/SSRQ_FR_I_2_8_0002_000.xml', '/SG/SSRQ_SG_III_4_015_1.xml')
    return
        map {
            "name": "tests:edition-text()",
            "description": "Check if the rendering of the edition text is correct for " || tokenize($id, '/')[last()],
            "exp": true(),
            "result": let $data := test-utils:fetch-get($tests:host || $id)
                        return
                            if ($data//*[@id = 'document-pane']//*[@class = 'tei-body5'] and not($data//*[@id = 'document-pane']//*[contains(./@class, 'tei-back')]))
                            then true()
                            else false()
        }
};

declare function tests:pagebreak() as map(*) {
    let $pb := <pb n="481" xmlns="http://www.tei-c.org/ns/1.0"/>
    return
        map {
            "name": "tests:pagebreak()",
            "description": "Check if the rendering for tei:pb is correct",
            "exp": <span class="alternate tei-pb11 pb-pagination"><span>[<span class="tei-desc3">S.</span> 481]</span><span class="altcontent">Seitenumbruch</span></span>,
            "result": $pm-config:web-transform($pb, map { "root": $pb }, $config:odd)
        }
};

declare function tests:abbr-list() as map(*) {
    let $abbr-list := <TEI xmlns="http://www.tei-c.org/ns/1.0" type="abbr">
                        <dataSpec ident="xxx">
                            <valList>
                                <valItem ident="ao">
                                    <desc xml:lang="de">anno</desc>
                                </valItem>
                            </valList>
                        </dataSpec>
                     </TEI>
    return
        map {
            "name": "tests:abbr-list()",
            "description": "Check if the rendering for abbr-lists is correct",
            "exp": <div class="tei-dataSpec2"><ul class="tei-valList2"><li class="tei-valItem2">ao = anno</li></ul></div>,
            "result": $pm-config:web-transform($abbr-list/tei:dataSpec, map { "root": $abbr-list}, $config:odd)
        }
};
