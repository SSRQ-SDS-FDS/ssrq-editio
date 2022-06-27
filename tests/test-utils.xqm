xquery version "3.1";

module namespace test-utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/test-utils";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../modules/config.xqm";
import module namespace http="http://expath.org/ns/http-client";
import module namespace doc-list="http://ssrq-sds-fds.ch/exist/apps/ssrq-data/doc-list" at "/db/apps/ssrq-data/modules/doc-list.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" at "../modules/templates.xqm";
import module namespace ssrq-helper="http://ssrq-sds-fds.ch/exist/apps/ssrq/helper" at "../modules/ssrq-helper.xqm";

declare variable $test-utils:templating-config :=  map {
                                                    $templates:CONFIG_APP_ROOT : $config:app-root,
                                                    $templates:CONFIG_STOP_ON_ERROR : true(),
                                                    $templates:CONFIG_PARAM_RESOLVER :
                                                        function($param) {
                                                            let $pval := array:fold-right(
                                                                [
                                                                    request:get-parameter($param, ()),
                                                                    request:get-attribute($param)
                                                                ], (),
                                                                function($zero, $current) {
                                                                    if (exists($zero)) then
                                                                        $zero
                                                                    else
                                                                        $current
                                                                }
                                                            )
                                                            return
                                                                if (exists($pval)) then
                                                                    $pval
                                                                else
                                                                    session:get-attribute("ssrq." || $param)
                                                    }
                                                };


declare function test-utils:fetch-get($url as xs:string) {
    let $request := <http:request method="GET" href="{$url}"/>
    let $response := http:send-request($request)
    return
        if (xs:int($response[1]/@status) = 200) then
            $response[2]
        else
            error(xs:QName('http:error'), 'Failed to fetch ' || $url)
};

declare function test-utils:fetch-get-headers($url as xs:string) {
    let $request := <http:request method="GET" href="{$url}"/>
    let $response := http:send-request($request)
    return
        $response[1]
};

declare function test-utils:mock-doc-load($idno as xs:string) as map(*) {
    let $idno-splitted := $idno => replace('(SSRQ|SDS|FDS)-', '') => tokenize('-')
    return
        map:merge((
            map{ "configuration": $test-utils:templating-config},
            ssrq-helper:load-by-idno(<div/>, map{}, $idno-splitted[1], $idno-splitted[2], ($idno-splitted[position() = 3 to last()] => string-join('-')), (), ())
        ))

};
