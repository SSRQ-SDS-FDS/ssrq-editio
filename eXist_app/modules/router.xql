xquery version "3.1";

declare namespace ssrq-router="http://ssrq-sds-fds.ch/exist/apps/ssrq/router";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization"; (: required for serialization :)

import module namespace roaster="http://e-editiones.org/roaster";
import module namespace router="http://e-editiones.org/roaster/router";
import module namespace rutil="http://e-editiones.org/roaster/util";
import module namespace errors="http://e-editiones.org/roaster/errors";
import module namespace auth="http://e-editiones.org/roaster/auth";

import module namespace occurrences-list="http://ssrq-sds-fds.ch/exist/apps/ssrq/occurrences/list" at "occurrences/list.xqm";
import module namespace views="http://ssrq-sds-fds.ch/exist/apps/ssrq/views" at "views.xqm";

declare variable $ssrq-router:definitions := ("views.json", "api.json");

(:~
 : This function "knows" all modules and their functions
 : that are imported here
 : You can leave it as it is, but it has to be here
 :)
declare function ssrq-router:lookup ($name as xs:string) {
    function-lookup(xs:QName($name), 1)
};


roaster:route($ssrq-router:definitions, ssrq-router:lookup#1, ())
