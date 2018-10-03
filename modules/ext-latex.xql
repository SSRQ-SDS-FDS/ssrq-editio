xquery version "3.1";

(:~
 : Extension functions for SSRQ.
 :)
module namespace pmf="http://www.tei-c.org/tei-simple/xquery/functions/ssrq-latex";

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace latex="http://www.tei-c.org/tei-simple/xquery/functions/latex";
import module namespace pmc="http://www.tei-c.org/tei-simple/xquery/functions/ssrq-common" at "ext-common.xql";

declare function pmf:alternote($config as map(*), $node as element(), $class as xs:string+, $content,
    $label, $type, $alternate) {
    let $nr := pmc:increment-counter($type)
    let $alternate := $config?apply-children($config, $node, $alternate)
    let $enclose := $type = "text-critical" and matches($content, "\w+\s+\w+")
    let $label :=
        switch($type)
            case "text-critical" return
                pmc:footnote-label($nr)
            default return
                $nr
    return
        if ($enclose) then
            ``[\textnotestart{`{$label}`}{`{$alternate}`}`{$config?apply-children($config, $node, $content)}`\textnoteend{`{$label}`}]``
        else (
            $config?apply-children($config, $node, $content),
            switch($type)
                case "text-critical" return
                    ``[\textnote[`{$label}`]{`{$alternate}`}]``
                default return
                    ``[\ednote[`{$label}`]{`{$alternate}`}]``
        )
};

declare function pmf:note($config as map(*), $node as node(), $class as xs:string+, $content as item()*, $place as xs:string?, $label, $type) {
    if (not($config?skip-footnotes)) then
        switch($place)
            case "margin" return (
                "\marginpar{\noindent\raggedleft\footnotesize " || latex:get-content($config, $node, $class, $content) || "}"
            )
            default return
                let $content := latex:get-content($config, $node, $class, $content)
                let $nr := pmc:increment-counter($type)
                let $label :=
                    switch($type)
                        case "text-critical" return
                            pmc:footnote-label($nr)
                        default return
                            $nr
                return
                    switch($type)
                        case "text-critical" return
                            ``[\textnote[`{$label}`]{`{$content}`}]``
                        default return
                            ``[\ednote[`{$label}`]{`{$content}`}]``
    else
        ()
};
