xquery version "3.1";

(:~
 : Shared extension functions for SSRQ.
 :)
module namespace pmf="http://www.tei-c.org/tei-simple/xquery/functions/ssrq-common";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace counters="http://www.tei-c.org/tei-simple/xquery/counters";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare variable $pmf:COUNTER_TEXTCRITICAL := "text-critical-" || util:uuid();
declare variable $pmf:COUNTER_NOTE := "note-" || util:uuid();

declare function pmf:prepare($config as map(*), $node as node()*) {
    (
        counters:destroy($pmf:COUNTER_TEXTCRITICAL),
        counters:destroy($pmf:COUNTER_NOTE),
        counters:create($pmf:COUNTER_TEXTCRITICAL),
        counters:create($pmf:COUNTER_NOTE)
    )[5]
};

declare function pmf:increment-counter($type as xs:string) {
    switch ($type)
        case "text-critical" case "text-critical-start" return
            counters:increment($pmf:COUNTER_TEXTCRITICAL)
        default return
            counters:increment($pmf:COUNTER_NOTE)
};

declare function pmf:scribe($scribe as attribute()?) {
    if ($scribe) then
        if (starts-with($scribe, 'per')) then
            <span class="scribe" data-ref="{$scribe}"/>
        else
            let $n := number($scribe)
            return
                if ($n = 1) then
                    ' ' || pmf:label('scribe1')
                else
                    ' ' || pmf:label('scribe2') || ' ' || $n - 1
    else
        ()
};


declare function pmf:span($content) {
    <span class="description">{
        for $node in $content
        return
        typeswitch($node)
            case xs:string return
                text { $node }
            default return
                $node
    }</span>
};

declare function pmf:label($id as xs:string?) {
    pmf:label($id, true())
};

declare function pmf:label($id as xs:string?, $upper as xs:boolean) {
    pmf:label($id, $upper, (session:get-attribute("ssrq.lang"), "de")[1])
};

declare function pmf:label($id as xs:string?, $upper as xs:boolean, $lang as xs:string) {
    if ($id) then
        let $label := $config:schema-odd//tei:dataSpec[@ident='ssrq.labels']//tei:valItem[@ident = $id]/tei:desc[@xml:lang = $lang]
        return
            if ($label) then
                if (count($label) > 1) then
                    ``[[Doppelte Übersetzung: `{$id}`, Sprache: `{$lang}`]]``
                else if ($upper) then
                    upper-case(substring($label, 1, 1)) || substring($label, 2)
                else
                    lower-case(substring($label, 1, 1)) || substring($label, 2)
            else
                ``[[Nicht übersetzt: `{$id}`, Sprache: `{$lang}`]]``
    else
        "[Missing label]"
};

declare function pmf:abbr($abbr as xs:string) {
    let $lang := (session:get-attribute("ssrq.lang"), "de")[1]
    let $val := $config:abbr//tei:valItem[@ident=$abbr]
    return (
        $val/tei:desc[@xml:lang = $lang]/string(),
        $val/tei:desc[1]/string()
    )[1]
};

(:~ Doppelpunkt einfügen unter Berücksichtigung frz. Typographie :)
declare function pmf:colon() {
    pmf:punct(':', true())
};

(:~ Französische Typographie erfordert Leerzeichen vor best. Interpunktionszeichen :)
declare function pmf:punct($char as xs:string, $spaceAfter as xs:boolean?) {
    let $lang := (session:get-attribute("ssrq.lang"), "de")[1]
    let $punct :=
        switch ($lang)
            case 'fr' return ' ' || $char
            default return $char
    return
        if ($spaceAfter) then
            $punct || ' '
        else
            $punct
};

declare function pmf:translate($attribute) {
    pmf:translate($attribute, 0, "uppercase")
};

declare function pmf:translate($attribute, $plural, $upper) {
    if ($attribute) then
        let $lang := (session:get-attribute("ssrq.lang"), "de")[1]
        let $element-name := local-name($attribute/..)
        let $attribute-name := local-name($attribute)
        let $value := $attribute/string()
        let $label:=
            if ($plural > 1) then
                if ($config:schema-odd//tei:elementSpec[@ident=$element-name]//tei:attDef[@ident=$attribute-name]//tei:valItem[@ident=$value]/tei:desc[@xml:lang=$lang][@type="plural"]) then
                    $config:schema-odd//tei:elementSpec[@ident=$element-name]//tei:attDef[@ident=$attribute-name]//tei:valItem[@ident=$value]/tei:desc[@xml:lang=$lang][@type="plural"]/string()
                else
                    $config:schema-odd//tei:elementSpec[@ident=$element-name]//tei:attDef[@ident=$attribute-name]//tei:valItem[@ident=$value]/tei:desc[@xml:lang=$lang][1]/string()
            else
                $config:schema-odd//tei:elementSpec[@ident=$element-name]//tei:attDef[@ident=$attribute-name]//tei:valItem[@ident=$value]/tei:desc[@xml:lang=$lang][1]/string()
        return
        switch ($upper)
            case "uppercase"
                return text{upper-case(substring($label,1,1)) || substring($label,2)}
            default
                return text{$label}
    else
        ()
};

declare function pmf:display-sigle($id as xs:string?) {
    let $components := tokenize($id, "_")
    return
        $components[1] || " " || $components[2] || "/" || $components[3]
};

declare function pmf:format-id($id as xs:string?) {
    let $temp  := replace($id, "^(.+?)_(\d{4}.*?)(?:_\d{1,2})?$", "$1 $2")
    let $parts := tokenize($temp)
    let $ssrq  := substring-before($parts[1], '_')
    let $vol   := replace(substring-after($parts[1], '_'), '_', '/')
    let $vol   := replace($vol, "^([A-Z]{2})/", "$1 ")      (: space after canton abbreviation :)
    let $id    :=
        if (matches($parts[2], '^\d{8}')) then
            replace($parts[2], '_', '-')
        else
            if (matches($parts[2], '^\d{4}_\d{3}')) then
                number(substring-before($parts[2], '_')) || '-' || number(substring-after($parts[2], '_'))
            else
                number($parts[2])
    return
        $ssrq || ' ' || $vol || ' ' || $id
};

declare function pmf:format-date($when as xs:string?) {
    pmf:format-date($when, (session:get-attribute("ssrq.lang"), "de")[1])
};

declare function pmf:format-date($when as xs:string?, $language as xs:string?) {
    if ($when) then
        text {
            try {
                if (matches($when, "^--\d+-\d+")) then
                    format-date(xs:date(replace($when, "^-(.*)$", "1900$1")), "[D1]. [MNn]", $language, (), ())
                else if (matches($when, "^--\d+")) then
                    format-date(xs:date(replace($when, "^-(.*)$", "1900$1-01")), "[MNn]", $language, (), ())
                else if (matches($when, "^\d{4}-\d{2}$")) then
                    format-date($when || '-01', "[MNn] [Y0001]")
                else if (matches($when, "^\d+$")) then
                    @when
                else
                    format-date(xs:date($when), "[D1].[M1].[Y0001]", $language, (), ())
            } catch * {
                @when
            }
        }
    else
        ()
};

declare function pmf:format-duration($duration as xs:string) {
    try {
        let $duration := xs:duration($duration)
        let $components := map:merge((
            pmf:get-duration-label("year", years-from-duration($duration)),
            pmf:get-duration-label("month", months-from-duration($duration)),
            pmf:get-duration-label("day", days-from-duration($duration)),
            pmf:get-duration-label("hour", hours-from-duration($duration))
        ))
        return
            string-join(
                map:for-each-entry($components, function($key, $value) {
                    if ($value > 0) then
                        $value || " " || $key
                    else
                        ()
                }),
                " "
            )
    } catch * {
        $duration
    }
};

declare function pmf:get-duration-label($name as xs:string, $quantity as xs:int) {
    let $lang := (session:get-attribute("ssrq.lang"), "de")[1]
    let $val := $config:schema-odd//tei:dataSpec[@ident='ssrq.labels']//tei:valItem[@ident=$name]
    return
        if ($val) then
            let $label :=
                if ($quantity > 1) then
                    ($val/tei:desc[@xml:lang = $lang][@type="plural"]/string(), $val/tei:desc[@xml:lang = $lang]/string())[1]
                else
                    $val/tei:desc[@xml:lang = $lang][not(@type = "plural")]/string()
            return
                map {
                    $label : $quantity
                }
        else
            map { $name: $quantity }
};

declare function pmf:footnote-label($nr as xs:int) {
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
