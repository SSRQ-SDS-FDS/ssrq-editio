xquery version "3.1";

module namespace test-suite="https://www.ssrq-sds-fds.ch/test-suite";

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
        "success": ($tests ! (if (.?passed) then . else ())) => count(),
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
                    if ($summary?total - $summary?success > 0)
                    then
                        <failures>
                        {
                            for $test in $tests
                            where $test?passed = false()
                            return
                                <testDetail>
                                    <message>„{$test?name}" failed</message>
                                    <testDescription>{$test?description}</testDescription>
                                    <expResult>{$test?exp}</expResult>
                                    <indeedResult>{$test?result}</indeedResult>
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
