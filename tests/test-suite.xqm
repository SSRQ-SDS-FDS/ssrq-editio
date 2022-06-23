xquery version "3.1";

module namespace test-suite="http://ssrq-sds-fds.ch/exist/apps/ssrq/test-suite";

(:~
: Simple testing-suite in pure XQuery
: This is the main function to check the results of tests and print out a short report
:
:
: @author Bastian Politycki, SSRQ
: @date 16.02.2022
: @param $result sequence of map with the following keys: 'name', 'description' 'exp', 'result'
: @return a report as node()
:)
declare function test-suite:print-result($results as map(*)*) as node() {
    let $tests := test-suite:test($results)
    let $summary := map {
        "success": $tests[.?passed] => count(),
        "total": $tests => count()
    }
    return
        <testReport>
            <summary>
                <success>{$summary?success} of {$summary?total} tests passed</success>
                <failure>{$summary?total - $summary?success} of {$summary?total} tests failed</failure>
            </summary>
            {
                (
                    if ($summary?success < $summary?total)
                    then
                        <failures>
                        {
                            for $test in $tests
                            where not($test?passed)
                            return
                                <testDetail>
                                    <message>„{$test?name}" failed</message>
                                    <testDescription>{$test?description}</testDescription>
                                    <expResult>{serialize($test?exp, map{"method":"json"})}</expResult>
                                    <indeedResult>{serialize($test?result, map{"method":"json"})}</indeedResult>
                                </testDetail>
                        }
                        </failures>
                    else ()
                )
            }
        </testReport>
};

declare function test-suite:test($results as map(*)*) as map(*)* {
    for $test in $results
    return
        $test => map:put("passed", deep-equal($test?exp, $test?result))
};
