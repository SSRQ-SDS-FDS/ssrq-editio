xquery version "3.0";

import module namespace pmu="http://www.tei-c.org/tei-simple/xquery/util";
import module namespace odd="http://www.tei-c.org/tei-simple/odd2odd";
import module namespace cache="http://exist-db.org/xquery/cache";
import module namespace config-data="http://ssrq-sds-fds.ch/exist/apps/ssrq-data/config" at "/db/apps/ssrq-data/modules/config.xqm";

declare namespace repo="http://exist-db.org/xquery/repo";

(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;

declare variable $repoxml :=
    let $uri := doc($target || "/expath-pkg.xml")/*/@name
    let $repo := util:binary-to-string(repo:get-resource($uri, "repo.xml"))
    return
        parse-xml($repo)
;

declare function local:generate-code($collection as xs:string) {
    for $source in ("ssrq.odd", "ssrq-norm.odd")
    for $module in ("web", "latex")
    for $file in pmu:process-odd(
        odd:get-compiled($collection || "/resources/odd", $source),
        $collection || "/transform",
        $module,
        "../transform",
        doc($collection || "/resources/odd/configuration.xml")/*)?("module")
    return
        (),
    let $permissions := $repoxml//repo:permissions[1]
    return (
        for $file in xmldb:get-child-resources($collection || "/transform")
        let $path := xs:anyURI($collection || "/transform/" || $file)
        return (
            sm:chown($path, $permissions/@user),
            sm:chgrp($path, $permissions/@group)
        )
    )
};

xmldb:create-collection($target, "transform"),
sm:chown(xs:anyURI($target || "/transform"), "ssrq"),
sm:chgrp(xs:anyURI($target || "/transform"), "tei"),
if (xs:boolean(doc($target || "/env.xml")//upload)) then
    sm:chmod(xs:anyURI($target || "/modules/pub/upload.xql"), "rwsr-xr-x")
else
    (),
cache:destroy($config-data:CACHE),
cache:create($config-data:CACHE, map {
    "maximumSize": 32768,
    "expireAfterAccess": 86400000 (: 1 day :)
}),
local:generate-code($target)
