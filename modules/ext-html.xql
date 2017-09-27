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

declare function pmf:reference($config as map(*), $node as element(), $class as xs:string+, $content,
    $ref, $label) {
    <span class="reference {$class}">
    <span>{$config?apply-children($config, $node, $content)}</span>
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
    let $labelStart := string-join(($label, if ($enclose) then "-" else ()))
    let $labelEnd := string-join((if ($enclose) then "-" else (), $label))
    return (
        if ($enclose) then
            <a class="note" rel="footnote" href="#fn:{$id}">
            { $labelStart }
            </a>
        else
            (),
        <span class="alternate {$class}">
            <span>{html:apply-children($config, $node, $content)}</span>
            <span class="altcontent">{$alternate}</span>
        </span>,
        <span id="fnref:{$id}">
            <a class="note" rel="footnote" href="#fn:{$id}">
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
                    case "text-critical" return
                        counter:next-value("text-critical")
                    default return
                        counter:next-value("note")
            let $content := $config?apply-children($config, $node, $content)
            return (
                <span id="fnref:{$id}">
                    <a class="note" rel="footnote" href="#fn:{$id}">
                    {
                        switch($type)
                            case "text-critical" return
                                pmf:footnote-label($nr)
                            default return
                                $nr
                    }
                    </a>
                </span>,
                <li class="footnote" id="fn:{$id}" value="{$nr}"
                    type="{if ($type = 'text-critical') then 'a' else '1'}">
                    <span class="fn-content">
                        {$content}
                    </span>
                    <a class="fn-back" href="#fnref:{$id}">↩</a>
                </li>
            )
};

declare %private function pmf:footnote-label($nr as xs:int) {
    string-join(reverse(pmf:footnote-label-recursive($nr)))
};


declare %private function pmf:footnote-label-recursive($nr as xs:int) {
    if ($nr > 0) then
        let $nr := $nr - 1
        return (
            codepoints-to-string(string-to-codepoints("a") + $nr mod 26),
            pmf:footnote-label($nr div 26)
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
