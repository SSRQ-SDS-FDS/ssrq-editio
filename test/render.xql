xquery version "3.1";

module namespace testRendering="http://existsolutions.com/ssrq/test";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei="http://www.tei-c.org/ns/1.0";


import module namespace ssrq-utils="http://existsolutions.com/ssrq/utils" at "../modules/ssrq-util.xqm";

(:declare
    %test:assertEquals('<span class="alternate tei-foreign text-critical"><span>blah</span><span class="altcontent">fr</span></span>')
function testRendering:foreign() {
    pm-web:transform(<foreign xmlns="http://www.tei-c.org/ns/1.0" xml:lang="fr">blah</foreign>, ())
};
:)

declare
    %test:assertEquals('23')
 function testRendering:cantonList() {
    count(ssrq-utils:listCantons(<div>test</div>, map{"root": ''}))
};
