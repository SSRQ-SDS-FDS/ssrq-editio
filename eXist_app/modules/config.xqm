xquery version "3.1";

(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="http://www.tei-c.org/tei-simple/config";

import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "utils.xqm";
import module namespace http="http://expath.org/ns/http-client" at "java:org.exist.xquery.modules.httpclient.HTTPClientModule";
import module namespace i18n-settings="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/settings" at "i18n/settings.xqm";
import module namespace ssrq-cache="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/cache" at "repository/cache.xqm";

import module namespace templates="http://exist-db.org/xquery/html-templating";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace jmx="http://exist-db.org/jmx";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xpath = 'http://www.w3.org/2005/xpath-functions';

(:~
 : Should documents be located by xml:id or filename?
 :)
declare variable $config:address-by-id := false();

(:
 : The default to use for determining the amount of content to be shown
 : on a single page. Possible values: 'div' for showing entire divs (see
 : the parameters below for further configuration), or 'page' to browse
 : a document by actual pages determined by TEI pb elements.
 :)
declare variable $config:default-view := "body";

(:
 : The element to search by default, either 'tei:div' or 'tei:body'.
 :)
declare variable $config:search-default := "tei:div";

(:
 : Defines which nested divs will be displayed as single units on one
 : page (using pagination by div). Divs which are nested
 : deeper than $pagination-depth will always appear in their parent div.
 : So if you have, for example, 4 levels of divs, but the divs on level 4 are
 : just small sub-subsections with one paragraph each, you may want to limit
 : $pagination-depth to 3 to not show the sub-subsections as separate pages.
 : Setting $pagination-depth to 1 would show entire top-level divs on one page.
 :)
declare variable $config:pagination-depth := 0;

(:
 : If a div starts with less than $pagination-fill elements before the
 : first nested div child, the pagination-by-div algorithm tries to fill
 : up the page by pulling following divs in. When set to 0, it will never
 : attempt to fill up the page.
 :)
declare variable $config:pagination-fill := 5;

(:
 : The CSS class to declare on the main text content div.
 :)
declare variable $config:css-content-class := "content";

declare variable $config:user-agent :=
    let $default-ua :=
        try {
            let $request := <http:request method="GET" href="http://localhost:{request:get-server-port()}/{request:get-context-path()}/rest/?_query=request:get-header(%27User-Agent%27)"/>
            let $response := http:send-request($request)
            return
                if ($response[1]/@status = "200") then
                    $response[2]/exist:result/exist:value/string()
                else
                    ()
        } catch * {
            ()
        }
    let $expath-descriptor := config:expath-descriptor()
    let $app-ua :=
        $expath-descriptor/@abbrev || "/" || $expath-descriptor/@version
    return
        string-join(($app-ua, $default-ua), " ")
;

declare variable $config:permalink-base := "//p.ssrq-sds-fds.ch/";

(:
    Determine the base URL for links.
:)
declare variable $config:default-base-url :=
    (request:get-context-path() || substring-after($config:app-root, "/db")) => replace('^(.*?)/?$', '$1')
;
declare variable $config:base-url :=
    let $site-prefix := request:get-header('X-Site-Prefix')
    return
        if (exists($site-prefix)) then
            $site-prefix => replace('^(.*?)/?$', '$1')
        else
            $config:default-base-url
;

declare variable $config:lang-settings := i18n-settings:get-lang-settings();

declare variable $config:index-url :=
    let $index-subdomain := 'index'
    return
        if ($config:base-url eq $config:default-base-url) then
           ('//', $config:env/urls/prefix[@type = 'index'] ,'.', $config:env/urls/url[@lang = $config:lang-settings?lang]) => string-join()
        else
            $config:base-url => replace('^//\w+(\..*)$', '//' || $config:env/urls/prefix[@type = 'index'] || '$1')
;


declare variable $config:app-titles := map {
    "de": "SSRQ online",
    "en": "SLS online",
    "fr": "SDS online",
    "it": "FDS online"
};

declare variable $config:app-root as xs:string := analyze-string(system:get-module-load-path(), '(/db.*)/modules')//xpath:group[@nr = "1"]/string();

declare variable $config:data-root := utils:path-concat-safe(($config:app-root, "editio-data"));

declare variable $config:temp-root := utils:path-concat-safe(($config:app-root, "temp"));

declare variable $config:env := doc($config:app-root || '/env.xml')/settings;

declare variable $config:odd := request:get-parameter("odd", $config:odd-diplomatic);

declare variable $config:odd-source := "ssrq-source.odd";

declare variable $config:odd-diplomatic := "ssrq.odd";

declare variable $config:odd-normalized := "ssrq-norm.odd";

declare variable $config:odd-root := utils:path-concat-safe(($config:app-root, "resources/odd"));

declare variable $config:schema-odd := collection(utils:path-concat-safe(($config:data-root, "misc/schema")));

declare variable $config:translations := doc(utils:path-concat-safe(($config:data-root, "misc/translations.xml")))/*;

declare variable $config:abbr := doc(utils:path-concat-safe(($config:data-root, "misc/abbr.xml")))/*;

declare variable $config:dynamic-cache-name := "ssrq-cache";

declare variable $config:dynamic-cache-setinngs := map {'max-size': 32768, 'max-age': 86400000};

declare variable $config:static-cache-name := "cache";

declare variable $config:static-cache-path := utils:path-concat-safe(($config:app-root, $config:static-cache-name));

declare variable $config:static-docs-list := 'docs.xml';

declare variable $config:static-docs-list-cache := ssrq-cache:load-from-static-cache-by-name($config:static-cache-path, $config:static-docs-list);

declare variable $config:static-filters-cache := 'filters.xml';

declare variable $config:static-filters-list-cache := ssrq-cache:load-from-static-cache-by-name($config:static-cache-path, $config:static-filters-cache);

declare variable $config:partners := doc(utils:path-concat-safe(($config:data-root, "misc/partners.xml")))/*;

declare variable $config:output := "transform";

declare variable $config:output-root := utils:path-concat-safe(($config:app-root, $config:output));

declare variable $config:module-config := doc(utils:path-concat-safe(($config:odd-root, "configuration.xml")))/*;

declare variable $config:repo-descriptor := doc(utils:path-concat-safe(($config:app-root, "repo.xml")))/repo:meta;

declare variable $config:app-resources := utils:path-concat-safe(($config:app-root, "resources"));

declare variable $config:i18n-catalogues := utils:path-concat-safe(($config:app-resources, "i18n"));

declare variable $config:i18n-supported-languages := ("de", "fr", "it", "en");

declare variable $config:i18n-default-lang := "de";

declare variable $config:i18n-supported-languages-display := ("DEU", "FRA", "ITA", "ENG");

declare variable $config:iso-639-3 := map {'de'     : 'deu',
                                          'fr'     : 'fra',
                                          'it'     : 'ita',
                                          'en'     : 'eng'
                                         };

declare variable $config:paratext-types := ("intro", "bailiffs", "lit");

declare variable $config:api-prefix := 'api';

declare variable $config:api-version := 'v1';

declare variable $config:ssrq-api-host := 'https://www.ssrq-sds-fds.ch';

declare variable $config:ssrq-places-db-std-name := $config:ssrq-api-host || '/places-db-edit/views/get-std-name.xq';

(: FIXME: using path-concat-safe here results in a NullPointerException
 : declare variable $config:expath-descriptor := doc(utils:path-concat-safe(($config:app-root, "expath-pkg.xml")))/expath:package;
 :)
declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

(:~
 : Return an ID which may be used to look up a document. Change this if the xml:id
 : which uniquely identifies a document is *not* attached to the root element.
 :)
declare function config:get-id($node as node()) {
    root($node)/*/@xml:id
};

(:~
 : Returns a path relative to $config:data-root used to locate a document in the database.
 :)
 declare function config:get-relpath($node as node()) {
     let $root := if (ends-with($config:data-root, "/")) then $config:data-root else $config:data-root || "/"
     return
         substring-after(document-uri(root($node)), $root)
 };

declare function config:get-identifier($node as node()) {
    if ($config:address-by-id) then
        config:get-id($node)
    else
        config:get-relpath($node)
};


(:~
 : Resolve the given path using the current application context.
 : If the app resides in the file system,
 :)
declare function config:resolve($rel-path as xs:string) {
    let $path := utils:path-concat-safe(($config:app-root, $rel-path))
    return
        if (starts-with($config:app-root, "/db")) then
            doc($path)
        else
            doc("file://" || $path)
};

(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
    $config:repo-descriptor
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    $config:expath-descriptor
};
