xquery version "3.1";

module namespace api="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/api";

import module namespace link="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/link" at "link.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $api:HOST := "https://www.ssrq-sds-fds.ch";

declare variable $api:STDNAME := $api:HOST || "/places-db-edit/views/get-std-name.xq";

(: declare variable $app:PLACES := $app:HOST || "/places-db-edit/views/get-infos.xq";
declare variable $app:PERSONS := $app:HOST || "/persons-db-api/";
declare variable $app:LEMMA := $app:HOST || "/lemma-db-edit/views/get-lem-infos.xq";
declare variable $app:KEYWORDS := $app:HOST || "/lemma-db-edit/views/get-key-infos.xq"; :)

declare function api:request-json($url as xs:string, $params as map(*)?) as map(*) {
  let $request-url := $url || link:build-query-string($params)
  return
    json-doc($request-url)
};
