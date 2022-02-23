(:~
 : Transform a given source into a standalone document using
 : the specified odd.
 :
 : @author Wolfgang Meier
 :)
xquery version "3.1";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xql";
import module namespace process="http://exist-db.org/xquery/process" at "java:org.exist.xquery.modules.process.ProcessModule";
import module namespace pages="http://www.tei-c.org/tei-simple/pages" at "pages.xql";
import module namespace tpu="http://www.tei-c.org/tei-publisher/util" at "lib/util.xql";
import module namespace app="http://existsolutions.com/ssrq/app" at "../ssrq.xql";

import module namespace utils="http://ssrq-sds-fds.ch/utils" at "../utils.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option output:method "text";
declare option output:html-version "5.0";
declare option output:media-type "text/text";

let $dummy := session:set-attribute("ssrq.lang", request:get-parameter("lang", "de"))

let $id := request:get-parameter("id", ())
let $doc := request:get-parameter("doc", ())
let $token := request:get-parameter("token", ())
let $source := request:get-parameter("source", ())
return (
    if ($token) then
        response:set-cookie("simple.token", $token)
    else
        (),
    if ($id or $doc) then
        let $xml := if ($id) then app:load(<div/>, map {}, $doc, (), $id, ())?data => root()  else pages:get-document($id)/tei:TEI
        let $config := tpu:parse-pi(root($xml), ())
		return
			string-join($pm-config:latex-transform($xml, map { "image-dir": utils:path-concat-safe((config:get-repo-dir(), $config:data-root)) || "/" }, $config?odd))
    else
        ()
)
