xquery version "3.1";

import module namespace test-suite="http://ssrq-sds-fds.ch/exist/apps/ssrq/test-suite" at "test-suite.xqm";
import module namespace tests="http://ssrq-sds-fds.ch/exist/apps/ssrq/tests" at "tests.xqm";
import module namespace inspect = "http://exist-db.org/xquery/inspection";


let $test-names :=
    let $query-tests := request:get-parameter('tests', ()) => tokenize(',')
    return
        if (count($query-tests) > 0) then
            for $t in $query-tests
            return
                if ($t => starts-with('tests:')) then
                    $t
                else
                    'tests:' || $t
        else
            inspect:inspect-module(xs:anyURI('tests.xqm'))//function[not(ancestor::function)]/@name/data()
let $test-functions :=
    $test-names ! function-lookup(xs:QName(xs:string(.)), 0)
let $test-results :=
    $test-functions ! .()
return
    test-suite:print-result($test-results)
