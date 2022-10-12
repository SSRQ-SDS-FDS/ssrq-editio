xquery version "3.1";

(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="http://www.tei-c.org/tei-simple/config";

import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "utils.xqm";
import module namespace http="http://expath.org/ns/http-client" at "java:org.exist.xquery.modules.httpclient.HTTPClientModule";

declare namespace templates="http://exist-db.org/xquery/templates";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace jmx="http://exist-db.org/jmx";
declare namespace tei="http://www.tei-c.org/ns/1.0";

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

(:~
 : Configuration XML for Apache FOP used to render PDF. Important here
 : are the font directories.
 :)
declare variable $config:fop-config :=
    let $fontsDir := config:get-fonts-dir()
    return
        <fop version="1.0">
            <!-- Strict user configuration -->
            <strict-configuration>true</strict-configuration>

            <!-- Strict FO validation -->
            <strict-validation>false</strict-validation>

            <!-- Base URL for resolving relative URLs -->
            <base>./</base>

            <renderers>
                <renderer mime="application/pdf">
                    <fonts>
                    {
                        if ($fontsDir) then (
                            <font kerning="yes"
                                embed-url="file:{$fontsDir}/LexiaFontes_Rg.ttf"
                                encoding-mode="single-byte">
                                <font-triplet name="Lexia Fontes" style="normal" weight="normal"/>
                            </font>,
                            <font kerning="yes"
                                embed-url="file:{$fontsDir}/LexiaFontes_Bd.ttf"
                                encoding-mode="single-byte">
                                <font-triplet name="Lexia Fontes" style="normal" weight="700"/>
                            </font>,
                            <font kerning="yes"
                                embed-url="file:{$fontsDir}/LexiaFontes_It.ttf"
                                encoding-mode="single-byte">
                                <font-triplet name="Lexia Fontes" style="italic" weight="normal"/>
                            </font>,
                            <font kerning="yes"
                                embed-url="file:{$fontsDir}/LexiaFontes_BdIt.ttf"
                                encoding-mode="single-byte">
                                <font-triplet name="Lexia Fontes" style="italic" weight="700"/>
                            </font>
                        ) else
                            ()
                    }
                    </fonts>
                </renderer>
            </renderers>
        </fop>
;

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

(:
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root :=
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;

declare variable $config:data-root := "/db/apps/ssrq-data/data";

declare variable $config:temp-root := "/db/apps/ssrq-data/data/temp";

declare variable $config:odd := request:get-parameter("odd", $config:odd-diplomatic);

declare variable $config:odd-diplomatic := "ssrq.odd";

declare variable $config:odd-normalized := "ssrq-norm.odd";

declare variable $config:odd-root := utils:path-concat-safe(($config:app-root, "resources/odd"));

declare variable $config:schema-odd := collection(utils:path-concat-safe(($config:data-root, "misc/schema")));

declare variable $config:translations := doc(utils:path-concat-safe(($config:data-root, "misc/translations.xml")))/*;

declare variable $config:abbr := doc(utils:path-concat-safe(($config:data-root, "misc/abbr.xml")))/*;

declare variable $config:docs-list := doc(utils:path-concat-safe(("/db/apps/ssrq-data/", "cache/docs.xml")));

declare variable $config:partners := doc(utils:path-concat-safe(($config:data-root, "misc/partners.xml")))/*;

declare variable $config:output := "transform";

declare variable $config:output-root := utils:path-concat-safe(($config:app-root, $config:output));

declare variable $config:module-config := doc(utils:path-concat-safe(($config:odd-root, "configuration.xml")))/*;

declare variable $config:repo-descriptor := doc(utils:path-concat-safe(($config:app-root, "repo.xml")))/repo:meta;

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

declare %templates:wrap function config:app-title($node as node(), $model as map(*)) as text() {
    $config:expath-descriptor/expath:title/text()
};

declare function config:app-meta($node as node(), $model as map(*)) as element()* {
    <meta xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$author/text()}"/>
};

(:~
 : For debugging: generates a table showing all properties defined
 : in the application descriptors.
 :)
declare function config:app-info($node as node(), $model as map(*)) {
    let $expath := config:expath-descriptor()
    let $repo := config:repo-descriptor()
    return
        <table class="app-info">
            <tr>
                <td>app collection:</td>
                <td>{$config:app-root}</td>
            </tr>
            {
                for $attr in ($expath/@*, $expath/*, $repo/*)
                return
                    <tr>
                        <td>{node-name($attr)}:</td>
                        <td>{$attr/string()}</td>
                    </tr>
            }
            <tr>
                <td>Controller:</td>
                <td>{ request:get-attribute("$exist:controller") }</td>
            </tr>
        </table>
};

(: Try to dynamically determine data directory by calling JMX. :)
declare function config:get-data-dir() as xs:string? {
    try {
        let $request := <http:request method="GET" href="http://localhost:{request:get-server-port()}/{request:get-context-path()}/status?c=disk"/>
        let $response := http:send-request($request)
        return
            if ($response[1]/@status = "200") then
                $response[2]//jmx:DataDirectory/string()
            else
                ()
    } catch * {
        ()
    }
};

declare function config:get-repo-dir() {
    let $data-dir := config:get-data-dir()
    let $pkg-root := $config:expath-descriptor/@abbrev || "-" || $config:expath-descriptor/@version
    return
        if ($data-dir) then
            utils:path-concat(($data-dir, "expathrepo", $pkg-root))
        else
            ()
};


declare function config:get-fonts-dir() as xs:string? {
    let $repo-dir := config:get-repo-dir()
    return
        if ($repo-dir) then
            utils:path-concat(($repo-dir, "resources", "fonts"))
        else
            ()
};
