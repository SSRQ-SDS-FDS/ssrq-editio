xquery version "3.1";

(:~
 : Extension functions for SSRQ.
 :)
module namespace pmf="http://www.tei-c.org/tei-simple/xquery/functions/ssrq-web";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace html="http://www.tei-c.org/tei-simple/xquery/functions";
import module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common" at "ext-common.xqm";


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
    (: no language parameter at the moment :)
    let $url :=
        typeswitch($node)
            case element(tei:persName) | element(tei:orgName) return
                "https://www.ssrq-sds-fds.ch/persons-db-edit/?query=" || $ref[1]
            case element(tei:placeName)  | element(tei:origPlace)  return
                "https://www.ssrq-sds-fds.ch/places-db-edit/views/view-place.xq?id=" || $ref
            case element(tei:term) return
                if (starts-with($ref, 'key')) then
                    "https://www.ssrq-sds-fds.ch/lemma-db-edit/views/view-keyword.xq?id=" || $ref
                else
                    "https://www.ssrq-sds-fds.ch/lemma-db-edit/views/view-lemma.xq?id=" || $ref
            default return $ref
    return
        <span class="reference {$class}">
            <span><span data-url="{$url}">{$config?apply-children($config, $node, $content)}</span></span>
            <span class="altcontent">
                {if ($label => ends-with(':')) then concat($label, ' ' ) else $label, if (empty($ref)) then () else <span class="ref" data-ref="{$ref}"/>}
            </span>
        </span>
};

declare function pmf:alternote($config as map(*), $node as element(), $class as xs:string+, $content,
    $label, $type, $alternate, $optional as map(*)) {
    let $nodeId :=
        if ($node/@exist:id) then
            $node/@exist:id
        else
            util:node-id($node)
    let $id := translate($nodeId, "-", "_")
    let $nr := ec:increment-counter($type)
    let $alternate := $config?apply-children($config, $node, $alternate)
    let $breaks := if ($node => name() = 'subst' and $node[tei:lb or tei:pb]) then $config?apply-children($config, $node, $node/tei:lb | $node/tei:pb) else()
    let $prefix := $config?apply-children($config, $node, $optional?prefix)
    let $label :=
        switch($type)
            case "text-critical" return
                ec:footnote-label($nr)
            default return
                $nr
    let $enclose := $type = "text-critical" and matches($content, "\s") or $node/@type = 'keyword'
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
        $breaks,
        <span class="alternate {$class}">
            <span>{html:apply-children($config, $node, $content)}</span>
            <span class="altcontent">{$prefix}{$alternate}</span>
        </span>,
        <span id="fnref:{$id}" class="note-wrap">
            <a class="note note-end" rel="footnote" href="#fn:{$id}">
            { $labelEnd }
            </a>
        </span>,
        <li class="footnote" id="fn:{$id}" value="{$nr}"
            type="{if ($type = 'text-critical') then 'a' else '1'}">
            <span class="fn-content">
                {$prefix}{$alternate}
            </span>
            <a class="fn-back" href="#fnref:{$id}">↩</a>
        </li>
    )
};

(: Custom behaviour, which will just render a footnote-mark without preceding content :)
declare function pmf:mark($config as map(*), $node as element(), $class as xs:string+, $content,
    $label, $type, $alternate, $optional as map(*)) {
    let $nodeId :=
        if ($node/@exist:id) then
            $node/@exist:id
        else
            util:node-id($node)
    let $id := translate($nodeId, "-", "_")
    let $nr := ec:increment-counter($type)
    let $alternate := $config?apply-children($config, $node, $alternate)
    let $prefix := $config?apply-children($config, $node, $optional?prefix)
    let $label :=
        switch($type)
            case "text-critical" return
                ec:footnote-label($nr)
            default return
                $nr
    let $enclose := $type = "text-critical" and matches($content, "\s") or $node/@type = 'keyword'
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
        <span id="fnref:{$id}" class="note-wrap">
            <a class="note note-end" rel="footnote" href="#fn:{$id}">
            { $labelEnd }
            </a>
        </span>,
        <li class="footnote" id="fn:{$id}" value="{$nr}"
            type="{if ($type = 'text-critical') then 'a' else '1'}">
            <span class="fn-content">
                {$prefix}{$alternate}{ec:colon()}{$config?apply-children($config, $node, $node)}
            </span>
            <a class="fn-back" href="#fnref:{$id}">↩</a>
        </li>
    )
};

declare function pmf:note($config as map(*), $node as element(), $class as xs:string+, $content, $place, $label, $type, $optional as map(*)) {
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
            let $nr := ec:increment-counter($type)
            let $content := $config?apply-children($config, $node, $content)
            let $prefix := $config?apply-children($config, $node, $optional?prefix)
            let $n :=
                switch($type)
                    case "text-critical" case "text-critical-start" return
                        ec:footnote-label($nr)
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
                        {$prefix}{$content}
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


(:~ Custom behaviour for rendering biblLists...
:
:)
declare function pmf:biblList($config as map(*), $node as element(), $class as xs:string+, $content as node()*) {
    <div class="tei-div7 biblList">
        <h4 class="archivelocation">{$node/tei:head/text()}</h4>
        <ul>
            {
                for $div in $node/tei:div
                return
                    <li>{if ($div/tei:listBibl/tei:head) then
                        $div/tei:listBibl/tei:head/text() || ec:colon()
                        else ()} {string-join($div/tei:listBibl/tei:bibl/tei:idno, '; ')}</li>

            }
        </ul>
    </div>
};

(:~
: Custom behaviour to render tei:head inside tei:table as thead
: @author: B. Politycki
: @date: 14.03.2022
:)
declare function pmf:thead($config as map(*), $node as element(), $class as xs:string+, $content as item()) as element(thead) {
    <thead>
        <tr>
            <th class="px-0" colspan="100">{html:apply-children($config, $node, $content)}</th>
        </tr>
    </thead>
};
