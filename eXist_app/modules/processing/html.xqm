xquery version "3.1";

module namespace html="http://ssrq-sds-fds.ch/exist/apps/ssrq/processing/html";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/templates" at "../i18n/i18n-templates.xqm";
import module namespace pm-web="http://www.tei-c.org/pm/models/ssrq/web/module" at "../../transform/ssrq-web-module.xql";
import module namespace norm-web="http://www.tei-c.org/pm/models/ssrq-norm/web/module" at "../../transform/ssrq-norm-web-module.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function html:create-and-postprocess($xml as element(), $parameters as map(*)?, $odd as xs:string?) as element()* {
    let $html as node()* := html:create($xml, $parameters, $odd)
    let $body := html:remove-footnotes($html)
    let $footnotes := html:extract-footnotes($html)
    return
        ($body, $footnotes)
};

(:~
: Create HTML output from TEI XML using
: the Publisher ODD Processing Model.
:
: @param $xml The TEI XML to transform
: @param $parameters The parameters to use for the transformation
: @param $odd The ODD to use for the transformation
: @return The HTML output
:)
declare function html:create($xml as element(), $parameters as map(*)?, $odd as xs:string?) as node() {
    switch ($odd)
        case "ssrq-norm.odd" return
            norm-web:transform($xml, html:create-parameters($xml, $parameters))
        default return
            pm-web:transform($xml, html:create-parameters($xml, $parameters))
};


(:~
: Create Parameters for the transformation
:
: @param $root The element to use as the root
: @param $parameters The parameters to use for the transformation as a map
: @return The parameters for the transformation as a map
:)
declare function html:create-parameters($root as element(), $parameters as map(*)?) as map(*) {
    let $default-parameters := map { "root": $root }
    return
        if ($parameters) then
            map:merge($default-parameters, $parameters)
        else
            $default-parameters
};


(:~
: Remove footnotes from the HTML
:
: @param $nodes The nodes to remove footnotes from
: @return The nodes without footnotes
:)
declare %private function html:remove-footnotes($nodes as node()*) as node()* {
    for $node in $nodes
    return
        typeswitch($node)
            case element(li) return
                if ($node/@class = "footnote") then
                    ()
                else
                    element { node-name($node) } {
                        $node/@*,
                        html:remove-footnotes($node/node())
                    }
            case element() return
                element { node-name($node) } {
                    $node/@*,
                    html:remove-footnotes($node/node())
                }
            default return
                $node
};


(:~
: Extract footnotes from the HTML.
: Was nav:output-footnotes in previous versions.
: Should be consired as deprecated.
:
: @param $html The HTML to extract footnotes from
: @return The footnotes as a div element
:)
declare %private function html:extract-footnotes($html as node()*) as element(section)? {
    if ($html//li[@class = "footnote"]) then
        let $footnotes := $html//li[@class = "footnote"][not(ancestor::li[@class = "footnote"])]
        return
            <section class="{$config:css-footnote-class}">
                <h4 class="block-title">
                    {i18n:create-i18n-container('notes')}
                </h4>
                <ol class="textcritical">
                {
                    for $note in $footnotes[@type="a"]
                    order by number($note/@value)
                    let $note :=
                        element { node-name($note) } {
                            $note/@*,
                            html:remove-nested-footnotes($note/node())
                        }
                    return
                        html:check-note($note)
                }
                </ol>
                <ol>
                {
                    for $note in $footnotes[@type="1"]
                    order by number($note/@value)
                    let $note :=
                        element { node-name($note) } {
                            $note/@*,
                            html:remove-nested-footnotes($note/node())
                        }
                    return
                        html:check-note($note)
                }
                </ol>
            </section>
    else
        ()
};

(:~
: Internal helper function.
: Was nav:remove-nested-footnotes in previous versions.
: Deprecated.
:)
declare %private function html:remove-nested-footnotes($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case element(li) return
                $node[@class="footnote"]
            case element() return
                element { node-name($node) } {
                    $node/@*,
                    html:remove-nested-footnotes($node/node())
                }
            default return
                $node
};

(:~
: Internal helper function.
: Was nav:check-note in previous versions.
: Deprecated.
:)
declare %private function html:check-note($note as element()) {
    if (matches($note/span[@class = "fn-content"], "[\.!\?]\s*$")) then
        $note
    else
        element { node-name($note) } {
            $note/@*,
            <span class="fn-content">{ $note/span[@class = "fn-content"]/node() }.</span>,
            $note/*[not(self::span)]
        }
};
