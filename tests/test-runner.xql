xquery version "3.1";

import module namespace test-suite="http://ssrq-sds-fds.ch/exist/apps/ssrq/test-suite" at "test-suite.xqm";
import module namespace tests="http://ssrq-sds-fds.ch/exist/apps/ssrq/tests" at "tests.xqm";
import module namespace inspect = "http://exist-db.org/xquery/inspection";


let $tests := inspect:inspect-module(xs:anyURI('tests.xqm'))

let $test-results :=
                        for $function in $tests//function[not(ancestor::function)]
                        let $result := function-lookup(xs:QName(xs:string($function/@name)), 0)
                        return $result()

return $test-results => test-suite:print-result()
