xquery version "3.1";

(:~
 : Shared extension functions for SSRQ.
 :)
module namespace pmf="http://www.tei-c.org/tei-simple/xquery/functions/ssrq-common";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function pmf:translate($element-name, $attribute-name, $value, $lang, $plural, $upper) {
    let $label:=
        if($plural > 1) then
            $config:schema-odd//tei:elementSpec[@ident=$element-name]//tei:attDef[@ident=$attribute-name]//tei:valItem[@ident=$value]/tei:desc[@xml:lang=$lang][@type="plural"]/string()
        else
            $config:schema-odd//tei:elementSpec[@ident=$element-name]//tei:attDef[@ident=$attribute-name]//tei:valItem[@ident=$value]/tei:desc[@xml:lang=$lang][1]/string()
    return
    switch ($upper)
        case "uppercase"
            return text{upper-case(substring($label,1,1)) || substring($label,2)}
        default
            return text{$label}
};

declare function pmf:display-sigle($id as xs:string) {
    let $components := tokenize($id, "_")
    return
        $components[1] || " " || $components[2] || "/" || $components[3]
};
