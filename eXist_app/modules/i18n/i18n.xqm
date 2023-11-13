module namespace i18n = 'http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/module';

(:~
    : I18N Internationalization Module
    : Based on: https://github.com/eXist-db/i18n/tree/master
    :
    :
:)

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace find="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/finder" at "../repository/finder.xqm";
import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "../utils.xqm";

(:~
 : Start processing the provided content using the modules defined by $modules. $modules should
 : be an XML fragment following the scheme:
 :
 : <modules>
 :       <module prefix="module-prefix" uri="module-uri" at="module location relative to apps module collection"/>
 : </modules>
 :
 : @param $content the sequence of nodes which will be processed
 : @param $modules modules to import
 : @param $model a sequence of items which will be passed to all called template functions. Use this to pass
 : information between templating instructions.
:)
declare function i18n:apply($content as node()+, $modules as element(modules), $model as item()*) {
    let $null := (
        request:set-attribute("$i18n:modules", $modules)
    )
    for $root in $content
        return
            i18n:process($root, (),())
};

(:~
 : Continue template processing on the given set of nodes. Call this function from
 : within other template functions to enable recursive processing of templates.
 :
 : @param $nodes the nodes to process
 : @param $model a sequence of items which will be passed to all called template functions. Use this to pass
 : information between templating instructions.
:)
declare function i18n:process($nodes as node()*, $selectedLang as xs:string?, $defaultLang as xs:string?) {
    let $default-lang := utils:coalesce($defaultLang, $config:i18n-default-lang)
    let $selected-lang := utils:coalesce($selectedLang, $config:lang-settings)
    for $node in $nodes
        let $selectedCatalogue := i18n:get-language-collection($selected-lang, $default-lang)
        return
            i18n:process($node, $selectedCatalogue)
};

(:~
 : recursive function to traverse through the document and to process all i18n prefixed nodes
 :
 : @param $node node to analyse if is an i18n:* node
 : @param $model a sequence of items which will be passed to all called template functions. Use this to pass
 : information between templating instructions.
:)
declare function i18n:process($node as node(), $selectedCatalogue as node()) {
    typeswitch ($node)
        case document-node() return
            for $child in $node/node() return i18n:process($child, $selectedCatalogue)

        case element(i18n:translate) return
            let $text := i18n:process($node/i18n:text,$selectedCatalogue)
            return
                i18n:translate($node, $text,$selectedCatalogue)

        case element(i18n:text) return
            i18n:get-localized-text($node,$selectedCatalogue)

        case element() return
            element { node-name($node) } {
                    i18n:translate-attributes($node,$selectedCatalogue),
                    for $child in $node/node() return i18n:process($child,$selectedCatalogue)
            }

        default return
            $node
};

declare function i18n:translate-attributes($node as node(), $selectedCatalogue as node()){
    for $attribute in $node/@*
        return i18n:translate-attribute($attribute, $node, $selectedCatalogue)
};

declare function i18n:translate-attribute($attribute as attribute(), $node as node(),$selectedCatalogue as node()){
    if(starts-with($attribute, 'i18n(')) then
        let $key :=
            if(contains($attribute, ",")) then
                substring-before(substring-after($attribute,"i18n("),",")
            else
                substring-before(substring-after($attribute,"i18n("),")")
        let $i18nValue :=
            if(exists($selectedCatalogue//msg[@key = $key])) then  (
                i18n:get-display-value-for-key($key, $selectedCatalogue)
            ) else
                substring-before(substring-after(substring-after($attribute,"i18n("),","),")")
        return
            attribute {name($attribute)} {$i18nValue}
    else
        $attribute


};

declare %private function i18n:get-display-value-for-key($key, $catalog-working){
    $catalog-working//msg[@key eq $key]/node()
};

(:
 : Get the localized value for a given key from the given catalgue
 : if no localized value is available, the default value is used
:)
declare function i18n:get-localized-text($textNode as node(), $selectedCatalogue as node()){
    if(exists($selectedCatalogue//msg[@key eq $textNode/@key])) then
        (i18n:get-display-value-for-key($textNode/@key, $selectedCatalogue))
    else
        $textNode/(text() | *)
};

(:~
 : function implementing i18n:translate to enable localization of strings containing alphabetical or numerical parameters
 :
 : @param $node i18n:translate node eclosing i18n:text and parameters to substitute
 : @param $text the processed(!) content of i18n:text
:)
declare function i18n:translate($node as node(),$text as xs:string,$selectedCatalogue as node()) {
    if(contains($text,'{')) then
        (: text contains parameters to substitute :)
        let $params := $node//i18n:param
        let $paramKey := substring-before(substring-after($text, '{'),'}')
        return
            if(number($paramKey) and exists($params[position() eq number($paramKey)])) then
                (: numerical parameters to substituce :)
                let $selectedParam := $node/i18n:param[number($paramKey)]
                return
                    i18n:replace-param($node, $selectedParam,$paramKey, $text,$selectedCatalogue)
            else if(exists($params[@key eq $paramKey])) then
                (: alphabetical parameters to substituce :)
                let $selectedParam := $params[@key eq $paramKey]
                return
                    i18n:replace-param($node, $selectedParam,$paramKey, $text,$selectedCatalogue)
            else
                (: ERROR while processing parmaters to substitute:)
                concat("ERROR: Parameter ", $paramKey, " could not be substituted")
    else
        $text
};

(:~
 : function replacing the parameter with its (localized) value
 :
 : @param $node     i18n:translate node eclosing i18n:text and parameters to substitute
 : @param $param    currently processed i18n:param as node()
 : @param $paramKey currently processed parameterKey (numerical or alphabetical)
 : @param $text     the processed(!) content of i18n:text
:)
declare function i18n:replace-param($node as node(), $param as node(),$paramKey as xs:string, $text as xs:string,$selectedCatalogue as node()) {
    if(exists($param/i18n:text)) then
        (: the parameter has to be translated as well :)
        let $translatedParam := i18n:get-localized-text($param/i18n:text, $selectedCatalogue)
        let $result := replace($text, concat("\{", $paramKey, "\}"), $translatedParam)
        return i18n:translate($node,$result,$selectedCatalogue)
    else
        (: simply substitute {paramKey} with it's param value' :)
        let $result := replace($text, concat("\{", $paramKey, "\}"), $param)
        return
            i18n:translate($node, $result,$selectedCatalogue)
};


(:
: Get the language collection for the given language
: If no collection is found, the default language collection is returned
:
: @param $selected-lang the language to search for as xs:string
: @param $default-lang the default language to search for as xs:string
: @return the language collection as element(catalogue)
:)
declare function i18n:get-language-collection($selected-lang as xs:string, $default-lang as xs:string) as element(catalogue) {
  let $catalogue := find:i18n-catalogue-by-lang($selected-lang)
  return
    if (exists($catalogue)) then
        $catalogue
    else
        find:i18n-catalogue-by-lang($default-lang)

};
