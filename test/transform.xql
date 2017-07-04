xquery version "3.1";

module namespace testTransform="http://existsolutions.com/ssrq/test";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace pm-web="http://www.tei-c.org/pm/models/ssrq/web/module" at "../transform/ssrq-web-module.xql";

declare
    %test:assertEquals('<span class="alternate tei-foreign text-critical"><span>blah</span><span class="altcontent">fr</span></span>')
function testTransform:foreign() {
    pm-web:transform(<foreign xmlns="http://www.tei-c.org/ns/1.0" xml:lang="fr">blah</foreign>, ())
};