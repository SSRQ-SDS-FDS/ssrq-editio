xquery version "3.1";

(:~
 : Extension functions for SSRQ.
 :)
module namespace pmf="http://www.tei-c.org/tei-simple/xquery/functions/ssrq-web";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace html="http://www.tei-c.org/tei-simple/xquery/functions";
import module namespace counter="http://exist-db.org/xquery/counter" at "java:org.exist.xquery.modules.counter.CounterModule";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

declare function pmf:prepare($config as map(*), $node as node()*) {
    (
        counter:destroy("text-critical"),
        counter:destroy("note"),
        counter:create("text-critical"),
        counter:create("note")
    )[5]
};

declare function pmf:link($config as map(*), $node as node(), $class as xs:string+, $content, $link, $target) {
    <a href="{$link}" class="{$class}">
    {
        if ($target) then
            attribute target { $target }
        else
            (),
        html:apply-children($config, $node, $content)
    }</a>
};

declare function pmf:reference($config as map(*), $node as element(), $class as xs:string+, $content,
    $ref, $label) {
    let $lang := (session:get-attribute("ssrq.lang"), "de")[1]
    let $url :=
        typeswitch($node)
            case element(tei:persName) | element(tei:orgName) return
                "https://www.ssrq-sds-fds.ch/persons-db-edit/?query=" || $ref[1] || "&amp;lang=" || $lang
            case element(tei:placeName)  | element(tei:origPlace)  return
                "https://www.ssrq-sds-fds.ch/places-db-edit/views/view-place.xq?id=" || $ref || "&amp;lang=" || $lang
            case element(tei:term) return
                if (starts-with($ref, 'key')) then
                    "https://www.ssrq-sds-fds.ch/lemma-db-edit/views/view-keyword.xq?id=" || $ref || "&amp;lang=" || $lang
                else
                    "https://www.ssrq-sds-fds.ch/lemma-db-edit/views/view-lemma.xq?id=" || $ref || "&amp;lang=" || $lang
            default return $ref
    return
        <span class="reference {$class}">
            <span><span data-url="{$url}">{$config?apply-children($config, $node, $content)}</span></span>
            <span class="altcontent">
                {$label, if (empty($ref)) then () else <span class="ref" data-ref="{$ref}"/>}
            </span>
        </span>
};

declare function pmf:alternote($config as map(*), $node as element(), $class as xs:string+, $content,
    $label, $type, $alternate) {
    let $nodeId :=
        if ($node/@exist:id) then
            $node/@exist:id
        else
            util:node-id($node)
    let $id := translate($nodeId, "-", "_")
    let $nr :=
        switch ($type)
            case "text-critical" return
                counter:next-value("text-critical")
            default return
                counter:next-value("note")
    let $alternate := $config?apply-children($config, $node, $alternate)
    let $label :=
        switch($type)
            case "text-critical" return
                pmf:footnote-label($nr)
            default return
                $nr
    let $enclose := $type = "text-critical" and matches($content, "\w+\s+\w+")
    let $labelStart := string-join(($label, if ($enclose) then "–" else ()))
    let $labelEnd := string-join((if ($enclose) then "–" else (), $label))
    return (
        if ($enclose) then
            <span class="note-wrap">
                <a class="note note-start" rel="footnote" href="#fn:{$id}">
                { $labelStart }
                </a>
            </span>
        else
            (),
        <span class="alternate {$class}">
            <span>{html:apply-children($config, $node, $content)}</span>
            <span class="altcontent">{$alternate}</span>
        </span>,
        <span id="fnref:{$id}" class="note-wrap">
            <a class="note note-end" rel="footnote" href="#fn:{$id}">
            { $labelEnd }
            </a>
        </span>,
        <li class="footnote" id="fn:{$id}" value="{$nr}"
            type="{if ($type = 'text-critical') then 'a' else '1'}">
            <span class="fn-content">
                {$alternate}
            </span>
            <a class="fn-back" href="#fnref:{$id}">↩</a>
        </li>
    )
};

declare function pmf:note($config as map(*), $node as element(), $class as xs:string+, $content, $place, $label, $type) {
    switch ($place)
        case "margin" return
            if ($label) then (
                <span class="margin-note-ref">{$label}</span>,
                <span class="margin-note">
                    <span class="n">{$label/string()}) </span>{ $config?apply-children($config, $node, $content) }
                </span>
            ) else
                <span class="margin-note">
                { $config?apply-children($config, $node, $content) }
                </span>
        default return
            let $nodeId :=
                if ($node/@exist:id) then
                    $node/@exist:id
                else
                    util:node-id($node)
            let $id := translate($nodeId, "-", "_")
            let $nr :=
                switch ($type)
                    case "text-critical" case "text-critical-start" return
                        counter:next-value("text-critical")
                    default return
                        counter:next-value("note")
            let $content := $config?apply-children($config, $node, $content)
            let $n :=
                switch($type)
                    case "text-critical" case "text-critical-start" return
                        pmf:footnote-label($nr)
                    default return
                        $nr
            return (
                <span id="fnref:{$id}" class="note-wrap">
                    <a class="note" rel="footnote" href="#fn:{$id}" data-label="{$n}">
                    { if ($type = "text-critical-start") then $n || "–" else $n }
                    </a>
                </span>,
                <li class="footnote" id="fn:{$id}" value="{$nr}"
                    type="{if ($type = ('text-critical','text-critical-start')) then 'a' else '1'}">
                    <span class="fn-content">
                        {$content}
                    </span>
                    <a class="fn-back" href="#fnref:{$id}">↩</a>
                </li>
            )
};

declare function pmf:notespan-end($config as map(*), $node as element(), $class as xs:string+, $content) {
    let $nodeId :=
        if ($content/@exist:id) then
            $content/@exist:id
        else
            util:node-id($content)
    let $id := translate($nodeId, "-", "_")
    return
        <tei-endnote class="note" rel="footnote" href="#fn:{$id}"/>
};

declare function pmf:finish($config as map(*), $input as node()*) {
    for $node in $input
    return
        typeswitch ($node)
            case element(tei-endnote) return
                let $start := root($node)//a[@href = $node/@href]
                return
                    <span class="note-wrap">
                        <a>
                        {
                            $node/@*,
                            "–" || $start/@data-label
                        }
                        </a>
                    </span>
            case element() return
                element { node-name($node) } {
                    $node/@*,
                    pmf:finish($config, $node/node())
                }
            default return
                $node
};

declare %private function pmf:footnote-label($nr as xs:int) {
    string-join(reverse(pmf:footnote-label-recursive($nr)))
};


declare %private function pmf:footnote-label-recursive($nr as xs:int) {
    if ($nr > 0) then
        let $nr := $nr - 1
        return (
            codepoints-to-string(string-to-codepoints("a") + $nr mod 26),
            pmf:footnote-label-recursive($nr div 26)
        )
    else
        ()
};

declare function pmf:copy($config as map(*), $node as element(), $class as xs:string+, $content) {
    $content ! $config?apply($config, pmf:copy(.))
};

declare %private function pmf:copy($nodes as node()*) {
    for $node in $nodes
    return
        typeswitch($node)
            case element() return
                element { node-name($node) } {
                    $node/@*,
                    pmf:copy($node/node())
                }
            default return $node
};

declare function pmf:caption($config as map(*), $node as element(), $class as xs:string+, $content) {
    <caption class="{$class}">{html:apply-children($config, $node, $content)}</caption>
};


declare function pmf:content($config as map(*), $node as node(), $class as xs:string+, $content as item()*) {
    typeswitch($content)
        case attribute() return
            text { $content }
        case text() return
            $content
        default return
            text { $content }
};
