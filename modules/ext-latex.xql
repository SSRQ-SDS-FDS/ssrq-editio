xquery version "3.1";

(:~
 : Extension functions for SSRQ.
 :)
module namespace pmf="http://www.tei-c.org/tei-simple/xquery/functions/ssrq-latex";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace latex="http://www.tei-c.org/tei-simple/xquery/functions/latex";
import module namespace pmc="http://www.tei-c.org/tei-simple/xquery/functions/ssrq-common" at "ext-common.xql";

declare function pmf:alternate($config as map(*), $node as node(), $class as xs:string+, $content, $default,
    $alternate) {
    latex:get-content($config, $node, $class, $default)
};

declare function pmf:alternote($config as map(*), $node as element(), $class as xs:string+, $content,
    $label, $type, $alternate, $optional as map(*)) {
    let $nr := pmc:increment-counter($type)
    let $enclose := $type = "text-critical" and matches($content, "\s")
    let $alternate := string-join($config?apply-children($config, $node, $alternate))
    let $content := string-join($config?apply-children($config, $node, $content))
    let $label :=
        switch($type)
            case "text-critical" return
                pmc:footnote-label($nr)
            default return
                $nr
    let $alternate :=
        if (exists($optional?prefix) and $type = "text-critical") then
            ``[\textup{`{$alternate}`}]``
        else
            $alternate
    let $prefix := latex:get-content($config, $node, $class, $optional?prefix)
    return
        if ($enclose) then
            ``[\leavevmode\textnotestart{`{$label}`}{`{$prefix}``{$alternate}`.}`{$content}`\textnoteend{`{$label}`}]``
        else (
            $content,
            switch($type)
                case "text-critical" return
                    ``[\leavevmode\textnote[`{$label}`]{`{$prefix}``{$alternate}`.}]``
                default return
                    ``[\leavevmode\ednote[`{$label}`]{`{$prefix}``{$alternate}`}]``
        )
};

declare function pmf:note($config as map(*), $node as node(), $class as xs:string+, $content as item()*, $place as xs:string?, $label, $type, $optional as map(*)) {
    if (not($config?skip-footnotes)) then
        switch($place)
            case "margin" return (
                "\marginpar{\noindent\raggedleft\footnotesize " || latex:get-content($config, $node, $class, $content) || "}"
            )
            default return
                let $content := string-join(latex:get-content($config, $node, $class, $content))
                let $nr := pmc:increment-counter($type)
                let $label :=
                    switch($type)
                        case "text-critical" return
                            pmc:footnote-label($nr)
                        default return
                            $nr
                let $content :=
                    if (exists($optional?prefix) and $type = "text-critical") then
                        ``[\textup{`{$content}`}]``
                    else
                        $content
                let $prefix := string-join(latex:get-content($config, $node, $class, $optional?prefix))
                return
                    switch($type)
                        case "text-critical" return
                            ``[\leavevmode\textnote[`{$label}`]{`{$prefix}``{$content}`.}]``
                        default return
                            ``[\leavevmode\ednote[`{$label}`]{`{$prefix}``{$content}`}]``
    else
        ()
};
