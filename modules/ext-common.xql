xquery version "3.1";

(:~
 : Shared extension functions for SSRQ.
 :)
module namespace pmf="http://www.tei-c.org/tei-simple/xquery/functions/ssrq-common";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

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
    <span class="description">{$content}</span>
};

declare function pmf:label($id as xs:string) {
    pmf:label($id, true())
};

declare function pmf:label($id as xs:string, $upper as xs:boolean) {
    pmf:label($id, $upper, (session:get-attribute("ssrq.lang"), "de")[1])
};

declare function pmf:label($id as xs:string, $upper as xs:boolean, $lang as xs:string) {
    let $label := $config:schema-odd//tei:dataSpec[@ident='ssrq.labels']//tei:valItem[@ident = $id]/tei:desc[@xml:lang = $lang]
    return
        if ($label) then
            if ($upper) then
                upper-case(substring($label, 1, 1)) || substring($label, 2)
            else
                lower-case(substring($label, 1, 1)) || substring($label, 2)
        else
            ``[[Nicht übersetzt: `{$id}`, Sprache: `{$lang}`]]``
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
        let $components := map {
            "Jahre": years-from-duration($duration),
            "Monate": months-from-duration($duration),
            "Tage": days-from-duration($duration),
            "Stunden": hours-from-duration($duration)
        }
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
