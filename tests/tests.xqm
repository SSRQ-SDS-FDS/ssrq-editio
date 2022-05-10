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

module namespace tests="http://ssrq-sds-fds.ch/exist/apps/ssrq/tests";

import module namespace app="http://ssrq-sds-fds.ch/exist/apps/ssrq/app" at "../modules/ssrq.xqm";
import module namespace test-utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/test-utils" at "test-utils.xqm";
import module namespace query="http://ssrq-sds-fds.ch/exist/apps/ssrq/search" at "../modules/ssrq-search.xqm";
import module namespace request ="http://exist-db.org/xquery/request";
import module namespace ssrq-helper="http://ssrq-sds-fds.ch/exist/apps/ssrq/helper" at "../modules/ssrq-helper.xqm";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../modules/config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../modules/pm-config.xql";
import module namespace cache="http://exist-db.org/xquery/cache";
import module namespace doc-list="http://ssrq-sds-fds.ch/exist/apps/ssrq-data/doc-list" at "/db/apps/ssrq-data/modules/doc-list.xqm";
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
    if (xs:boolean($ssrq-helper:ENV//cache/text())) then
        for $fragment in ('/?kanton=SG', '/?kanton=SG&amp;volume=SG_III_4&amp;start=41', '/NE/SDS_NE_3_002.xml?odd=ssrq.odd&amp;view=body')
        let $clear := cache:clear('ssrq-cache')
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
    else
        map {
           "name": "tests:cache-handling()",
            "description": "Test-fallback if caching is disabled",
            "exp": "false()",
            "result": false()
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

declare function tests:bibl-struct-thesis() as map(*)* {
    let $bibl := <biblStruct xmlns="http://www.tei-c.org/ns/1.0" xml:id="chbsg000145044">
                    <!-- Thesis -->
                    <monogr>
                        <!-- author origin: MARC 100 -->
                        <author>Frey, Stefan</author>
                        <title>Fromme feste Junker : neuer Stadtadel im spätmittelalterlichen Zürich</title>
                        <title type="short">Frey 2017</title>
                        <note>Dissertation phil. xyz</note>
                        <imprint>
                        <!-- publisher origin: MARC 502 -->
                        <publisher>Universität Zürich</publisher>
                        <!-- pubPlace origin: MARC 264 -->
                        <pubPlace>Zürich</pubPlace>
                        <!-- date origin: MARC 264 -->
                        <date>[2017]</date>
                        <date>© 2017</date>
                        </imprint>
                    </monogr>
                </biblStruct>
    let $exp := 'Frey, Stefan: Fromme feste Junker – neuer Stadtadel im spätmittelalterlichen Zürich, Dissertation, Zürich [2017] (Frey 2017).'
    let $results := ($pm-config:web-transform($bibl, map{"root": $bibl, "template": "introduction"}, $config:odd)//string() => normalize-space(), $pm-config:latex-transform($bibl, map{"root": $bibl}, $config:odd)[1] => normalize-space())
    for $result in $results
    return
        map {
            "name": "tests:bibl-struct-thesis()",
            "description": "Tests the rendering of tei:biblStruct for theses",
            "exp": $exp,
            "result": $result
        }
};

declare function tests:date-tooltips() as map(*)* {
    let $cases := (<date xmlns="http://www.tei-c.org/ns/1.0" when="2020-03-21">Samedi 21 mars 2020</date>, <date xmlns="http://www.tei-c.org/ns/1.0" when="2020-03-21" period="P7WD">Samedi 21 mars 2020</date>)
    let $exp := ('Datum: 21.3.2020', 'Datum: Samstag, 21.3.2020')
    for $case at $i in $cases
    return
        map {
            "name": "tests:date-tooltips()",
            "description": "Tests the content of the tooltip for tei:date in different circumstances",
            "exp": $exp[$i],
            "result": $pm-config:web-transform($case, map {"root": $case }, $config:odd)//span[@class = 'altcontent']/text() => normalize-space()
        }

};

declare function tests:heading-web() as map(*)* {
    let $cases := (
        <head xmlns="http://www.tei-c.org/ns/1.0"  type="title">Titel 1</head>,
        <head xmlns="http://www.tei-c.org/ns/1.0"  type="subtitle">Titel 2</head>,
        <head xmlns="http://www.tei-c.org/ns/1.0"  type="subsubtitle">Titel 3</head>
        )
    let $exp := ('h1', 'h2', 'h3')
    for $case at $i in $cases
    return
        map {
            "name": "tests:heading-web()",
            "description": "Test rendering of heading with @type eq " || $case/@type/data(.),
            "exp": $exp[$i],
            "result": $pm-config:web-transform($case, map { "root": $case}, $config:odd) => name()
        }
};

declare function tests:heading-tex() as map(*)* {
    let $cases := (
        <head xmlns="http://www.tei-c.org/ns/1.0"  type="title">Titel 1</head>,
        <head xmlns="http://www.tei-c.org/ns/1.0"  type="subtitle">Titel 2</head>,
        <head xmlns="http://www.tei-c.org/ns/1.0"  type="subsubtitle">Titel 3</head>
        )
    for $case in $cases
    return
        map {
            "name": "tests:heading-tex()",
            "description": "Test the rendering of heading @type eq " || $case/@type/data(.),
            "exp": "\vspace{1.5mm} \noindent "|| $case/text() || " \vspace{1.5mm}",
            "result": $pm-config:latex-transform($case, map{ "root": $case}, $config:odd)[1] => normalize-space()
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

declare function tests:table-web() as map(*)* {
    let $cases := (<table xmlns="http://www.tei-c.org/ns/1.0"><row><cell>Inhalt</cell></row></table>, <table xmlns="http://www.tei-c.org/ns/1.0"><head>head</head><row><cell>Inhalt</cell></row></table>)
    let $results := (<table class="tei-table"><tr class="tei-row2"><td class="tei-cell">Inhalt</td></tr></table>, <table class="tei-table"><thead><tr><th class="px-0" colspan="100">head</th></tr></thead><tr class="tei-row2"><td class="tei-cell">Inhalt</td></tr></table>)
    for $case at $i in $cases
    return
        map {
            "name": "tests:table-web()",
            "description": "Tests the rendition of a table for the web",
            "exp": $results[$i],
            "result": $pm-config:web-transform($case, map { "root": $case }, $config:odd)
        }
};

declare function tests:seg() as map(*)* {
    let $test-case := <seg xmlns="http://www.tei-c.org/ns/1.0" n="1"><p>Hier steht Text</p></seg>
    let $results := (
        map {
            "result": <span class="tei-seg5"><div class="tei-p4">Hier steht Text</div></span>,
            "odd": $config:odd,
            "test": $test-case,
            "case": "web"
        },
        map {
            "result": <div class="tei-seg5"><p class="tei-p1">[1] Hier steht Text</p></div>,
            "odd": $config:odd-normalized,
            "test": $test-case,
            "case": "web"
        },
        map {
            "result": <div class="tei-seg1 seg">[1] <p class="tei-p3">Hier steht Text</p></div>,
            "odd": $config:odd-normalized,
            "test":  <seg xmlns="http://www.tei-c.org/ns/1.0" n="1"><lb/><p>Hier steht Text</p></seg>,
            "case": "web"
        },
        map {
            "result": "[1] Hier steht Text",
            "odd": $config:odd,
            "test": $test-case,
            "case": "LaTeX"
        }
    )
    for $result in $results
    return
        map {
            "name": "tests:seg()",
            "description": "Tests the rendition of tei:seg for " || string-join(($result?case, $result?odd), ' rendered with ' ),
            "exp": $result?result,
            "result": if ($result?case = 'web') then
                        $pm-config:web-transform($result?test, map { "root": $result?test}, $result?odd)
                        else $pm-config:latex-transform($result?test, map { "root": $result?test}, $result?odd)[1] => normalize-space()
        }
};
