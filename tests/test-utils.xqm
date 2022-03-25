xquery version "3.1";

module namespace test-utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/test-utils";

import module namespace http="http://expath.org/ns/http-client";


declare function test-utils:fetch-get($url as xs:string) {
    let $request := <http:request method="GET" href="{$url}"/>
    let $response := http:send-request($request)
    return
        if ($response[1]/@status = "200") then
            $response[2]
        else
            error(xs:QName('http:error'), 'Failed to fetch ' || $url)
};
