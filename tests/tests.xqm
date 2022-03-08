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

import module namespace app="http://existsolutions.com/ssrq/app" at "../modules/ssrq.xqm";
import module namespace test-utils="https://www.ssrq-sds-fds.ch/test-utilts" at "test-utils.xqm";
import module namespace query="http://existsolutions.com/ssrq/search" at "../modules/ssrq-search.xqm";
import module namespace request ="http://exist-db.org/xquery/request";
import module namespace ssrq-utils="http://existsolutions.com/ssrq/utils" at "../modules/ssrq-util.xqm";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../modules/config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../modules/pm-config.xql";
import module namespace templates="http://exist-db.org/xquery/templates" at "../modules/templates.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $tests:host := substring-before(request:get-url(), '/exist') || '/exist/apps/ssrq';


(:~ *********************
: Tests to check general functionality
:
:
: ***********************
:)

declare function tests:get-relpath() as map(*)* {
    for $doc in ('FR/FR_I_2_8/SSRQ_FR_I_2_8_0001.xml', 'SG/SG_III_4/SSRQ_SG_III_4_001_1.xml')
    return
        map {
           "name": "tests:get-relpath()",
           "description": "Tests if correct relational path in SSRQ-data is found for " || ($doc => tokenize('/'))[last()],
           "exp": $doc,
           "result": doc(($config:data-root, $doc) => string-join('/'))/tei:TEI => config:get-relpath()
        }
};

declare function tests:find-document() as map(*)*{
    for $id in ('SSRQ_FR_I_2_8_0001', 'SSRQ_FR_I_2_8_0002_000', 'SSRQ_SG_III_4_015_1')
    return
        map {
            "name": "tests:find-document()",
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
    for $term in ('Hexe', 'Gericht', 'Richter', 'Urkunde')
    return
        map {
            "name": "tests:existing-search-terms()",
            "description": "Test if there are search results for " || $term,
            "exp": true(),
            "result": let $search := query:query-texts('', $term)
                        return $search?hits => count() > 0
        }
};

declare function tests:search-hit-rendering() as map(*)*{
    let $config-map := map {
        $templates:CONFIG_APP_ROOT : $config:app-root,
        $templates:CONFIG_STOP_ON_ERROR : true()
        }
    for $term in('Hexe', 'Gericht', 'Richter', 'Urkunde')
    let $result := query:query(<div/>, map{}, 'text', ('title', 'comment', 'idno', 'notes', 'seal', 'literature', 'edition', 'regest'), $term, (), (), true())
    return
        map {
            "name": "tests:search-hit-rendering()",
            "description": "Basic test to check the rendering of search results for a given term. Query was: " || $term,
            "exp": $result?hits => count(),
            "result": let $rendered-results := query:show-hits(<div/>, $result => map:put("configuration", $config-map), 1, $result?hits => count(), (), ()) ! .[1]
                        return $rendered-results => count()
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

declare function tests:paragraph() as map(*)* {
    let $para := <p xmlns="http://www.tei-c.org/ns/1.0">This is a paragraph</p>
    let $results := ($pm-config:web-transform($para, map{"root": $para}, $config:odd), $pm-config:latex-transform($para, map{"root": $para}, $config:odd)[1])
    let $exp := (<div class="tei-p4">This is a paragraph</div>, "This is a paragraph")
    for $case at $i in ('web', 'print')
    return
        map {
            "name": "tests:paragraph()",
            "description": "Tests the rendering of tei:p for " || $case,
            "exp": $exp[$i],
            "result": $results[$i]
        }
};
