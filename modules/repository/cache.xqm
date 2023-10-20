xquery version "3.1";

module namespace ssrq-cache="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/cache";

import module namespace cache="http://exist-db.org/xquery/cache" at "java:org.exist.xquery.modules.cache.CacheModule";
import module namespace request="http://exist-db.org/xquery/request" at "java:org.exist.xquery.functions.request.RequestModule";
import module namespace sm="http://exist-db.org/xquery/securitymanager" at "java:org.exist.xquery.functions.securitymanager.SecurityManagerModule";
import module namespace xmldb="http://exist-db.org/xquery/xmldb" at "java:org.exist.xquery.functions.xmldb.XMLDBModule";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(: ~
: A module containing functions to store or load query-results from the cache.
: This module differentiates between the different types of caches:
: 1) Dynamic cache: The cache is using the internal eXist-caching mechanism.
: 2) Static cache: The cache is using the file-system / the DB-layer to store the results.
:)

(:~~
: Create a static, file-system based cache.
:
: @param $dir The directory where the cache should be created as xs:string
: @param $name The name of the cache as xs:string
: @param $user The user who should own the cache as xs:string
: @param $group The group who should own the cache as xs:string
: @return true() if the cache was created successfully, false() otherwise
:)
declare function ssrq-cache:create-static-cache-dir($dir as xs:string, $name as xs:string, $user as xs:string, $group as xs:string) as xs:boolean {
    try {
            let $static-cache-dir as xs:anyURI := xs:anyURI($dir || '/' || $name)
            let $_ :=
                (
                    xmldb:create-collection($dir, $name),
                    sm:chown($static-cache-dir, $user),
                    sm:chgrp($static-cache-dir, $group)
                )
            return
                true()

        } catch * {
            false()
        }
};


(: Creates a cache with a given max-size and max-age.
:
: @param $name The name of the cache as xs:string
: @param $max-size The maximum size of the cache as xs:int
: @param $max-age The maximum age of the cache as xs:int
: @return true() if the cache was created successfully, false() otherwise
:)
declare function ssrq-cache:create-dynamic-cache($name as xs:string, $max-size as xs:int, $max-age as xs:int) as xs:boolean {
    cache:create($name,  map {"maximumSize": $max-size, "expireAfterAccess": $max-age})
};


(:~
: Destroy a cache, if it exists.
:
: @param $name The name of the cache as xs:string
: @return true() if the cache was destroyed successfully, false() otherwise as xs:boolean
:)
declare function ssrq-cache:destroy-cache-if-exists($cache-name as xs:string) as xs:boolean {
    ssrq-cache:apply-if-cache-exists($cache-name, 'cache:destroy', 1, $cache-name) => empty()
};


(:~
: Store content in the dynamic cache and create a unique key, if no key is given.
:
: @param $cache-name The name of the cache as xs:string
: @param $prefix The prefix for the key as xs:string?
: @param $value The content to be stored as item()*
: @return The unique key as xs:string
:)
declare function ssrq-cache:store-in-dynamic-cache($cache-name as xs:string, $key as xs:string?, $value as item()*) as xs:string {
    let $computed-key := if ($key) then $key else ssrq-cache:create-unique-cache-key(())
    let $_ := cache:put($cache-name, $computed-key, $value)
    return
        $key
};


(:~
: Load content from the dynamic cache, if the cache exists.
:
: @param $cache-name The name of the cache as xs:string
: @param $key The key for the content as xs:string
: @return The content as item()* or false() if the cache does or the key does not exist
:)
declare function ssrq-cache:load-from-dynamic-cache($cache-name as xs:string, $key as xs:string) as item()+ {
    (
        ssrq-cache:apply-if-cache-exists($cache-name, 'cache:get', 2, ($cache-name, $key)),
        false()
    )[1]
};


(:~
: Create a unique key based on the current request.
:
: @param $prefix The prefix for the key as xs:string?
: @return The unique key as xs:string
:)
declare function ssrq-cache:create-unique-cache-key($prefix as xs:string?) as xs:string {
    (
        $prefix, ssrq-cache:get-context-name-from-request(),
        ssrq-cache:get-parameter-names-from-request(),
        $config:lang-settings?lang
    )
    => string-join('_')
};


(:~
: Apply a function if a cache with the given name exists.
:
: @param $cache-name The name of the cache as xs:string
: @param $function-name The name of the function as xs:string
: @param $arity The arity of the function as xs:int
: @param $args The arguments for the function as item()*
: @return The result of the function as item()*
:)
declare %private function ssrq-cache:apply-if-cache-exists($cache-name as xs:string, $function-name as xs:string, $arity as xs:int, $args as item()*) as item()* {
    let $callback := function-lookup(xs:QName($function-name), $arity)
    return
        if ($cache-name = cache:names()) then
            apply($callback, array{$args ! .})
        else
            ()
};

declare %private function ssrq-cache:get-context-name-from-request() as xs:string {
    substring-after(request:get-url(), $config:app-root) => replace('/', '')
};


declare %private function ssrq-cache:get-parameter-names-from-request() as xs:string* {
    for $param in request:get-parameter-names()[not(. = 'lang') and not(. = 'doc')]
    return
        request:get-parameter($param, ())
};
