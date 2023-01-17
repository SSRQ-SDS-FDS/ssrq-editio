xquery version "3.1";

(:~
: A simple utility module to extend the
: functionality around the publisher processing model
:
:
: @author: Bastian Politycki
: @date: 28.10.2022
:
:)

module namespace ssrq-pm="http://ssrq-sds-fds.ch/exist/apps/ssrq/pm";

import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "utils.xqm";
import module namespace util="http://exist-db.org/xquery/util";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~ A simple wrapper function for odd-chaining
:
: @author: Bastian Politycki
: @date: 28.10.2022
:)
declare function ssrq-pm:compile-odd-to-odd($collection as xs:string, $source-name as xs:string, $target-name as xs:string) {
    xmldb:store(
        $collection,
        $target-name,
        (utils:path-concat(($collection, $source-name)) => doc())/tei:TEI => ssrq-pm:transform-odd-to-odd()
    )
};

declare function ssrq-pm:transform-odd-to-odd($source as node()*) as node()* {
    for $node in $source
    return
        typeswitch ($node)
        case text() return $node
        case element(tei:specGrpRef) return
            utils:path-concat(($node => util:collection-name(), $node/@target/data(.)))
            => doc()
        case element() return
             element { node-name($node) } {
                $node/@*,
                (: explicit copy of all namespaces except xml and default namespace :)
                for $n in $node => in-scope-prefixes()
                where not($n = ('xml', ''))
                return
                    namespace{$n} {namespace-uri-for-prefix($n, $node)},
                ssrq-pm:transform-odd-to-odd($node/node())
             }
        default return ()
};
