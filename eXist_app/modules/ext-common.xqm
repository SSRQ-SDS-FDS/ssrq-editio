xquery version "3.1";

(:~
 : Shared extension functions for SSRQ.
 :)
module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace counters="http://www.tei-c.org/tei-simple/xquery/counters";
import module namespace functx="http://www.functx.com";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "utils.xqm";
import module namespace ssrq-cache="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/cache" at "repository/cache.xqm";
import module namespace idno-parser="http://ssrq-sds-fds.ch/exist/apps/ssrq/parser/idno" at "parser/idno.xqm";


declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace i18n="http://exist-db.org/xquery/i18n";
declare namespace xpath = 'http://www.w3.org/2005/xpath-functions';

declare variable $ec:COUNTER_TEXTCRITICAL := "text-critical-" || util:uuid();
declare variable $ec:COUNTER_NOTE := "note-" || util:uuid();

declare variable $ec:language := $config:lang-settings?lang;
declare variable $ec:prefix := '^(?:SSRQ|SDS|FDS)-';

declare function ec:prepare($config as map(*), $node as node()*) {
    (
        counters:destroy($ec:COUNTER_TEXTCRITICAL),
        counters:destroy($ec:COUNTER_NOTE),
        counters:create($ec:COUNTER_TEXTCRITICAL),
        counters:create($ec:COUNTER_NOTE)
    )[5]
};

declare function ec:increment-counter($type as xs:string) {
    switch ($type)
        case "text-critical" case "text-critical-start" return
            counters:increment($ec:COUNTER_TEXTCRITICAL)
        default return
            counters:increment($ec:COUNTER_NOTE)
};

declare function ec:scribe($scribe as attribute()?) {
    if ($scribe) then
        if (starts-with($scribe, 'per')) then
            <span class="scribe" data-ref="{$scribe}"/>
        else
            let $nr := number($scribe)
            return
                if ($nr = 1) then
                    ec:label('mainScribe', false()) || ' (' || codepoints-to-string(string-to-codepoints("A") + $nr - 1) || ')'
                else
                    ec:label('secondaryScribe', false()) || ' (' || codepoints-to-string(string-to-codepoints("A") + $nr - 1) || ')'
    else
        ()
};


declare function ec:span($content) {
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

declare function ec:label($id as xs:string?) {
    ec:label($id, true())
};

declare function ec:label($id as xs:string?, $upper as xs:boolean) {
    ec:label($id, $upper, 0)
};

declare function ec:label($id as xs:string?, $upper as xs:boolean, $plural as xs:integer) {
    ec:label($id, $upper, $plural, $config:lang-settings?lang)
};

declare function ec:label($id as xs:string?, $upper as xs:boolean, $plural as xs:integer, $lang as xs:string) {
    if ($id) then
        let $label :=
            if ($plural > 1) then
                if ($config:translations//tei:dataSpec[@ident='ssrq.labels']//tei:valItem[@ident = $id]/tei:desc[@xml:lang = $lang][@type="plural"]) then
                    $config:translations//tei:dataSpec[@ident='ssrq.labels']//tei:valItem[@ident = $id]/tei:desc[@xml:lang = $lang][@type="plural"]/text()
                else
                    $config:translations//tei:dataSpec[@ident='ssrq.labels']//tei:valItem[@ident = $id]/tei:desc[@xml:lang = $lang][1]/text()
            else
                $config:translations//tei:dataSpec[@ident='ssrq.labels']//tei:valItem[@ident = $id]/tei:desc[@xml:lang = $lang][1]   (: doesn't work for <hi rend="sup">e</hi>, just returns 'e' :)
        return
            if ($label) then
                if (count($label) > 1) then
                    ``[[Doppelte Übersetzung: `{$id}`, Sprache: `{$lang}`]]``
                else if ($upper) then
                    upper-case(substring($label, 1, 1)) || substring($label, 2)
                else
                    $label
            else
                ``[[Nicht übersetzt: `{$id}`, Sprache: `{$lang}`]]``
    else
        "[Missing label]"
};


(:~ Doppelpunkt einfügen unter Berücksichtigung frz. Typographie :)
declare function ec:colon() {
    ec:punct(':', true())
};

(:~ Strichpunkt einfügen unter Berücksichtigung frz. Typographie :)
declare function ec:semicolon() {
    ec:punct(';', true())
};

(:~ Französische Typographie erfordert Leerzeichen vor best. Interpunktionszeichen :)
declare function ec:punct($char as xs:string, $space-after as xs:boolean?) {
    let $lang := $config:lang-settings?lang
    let $punct :=
        switch ($lang)
            case 'fr' return ' ' || $char
            default return $char
    return
        if ($space-after) then
            $punct || ' '
        else
            $punct
};

(:~
 : Return translation of an attribute value, when the schema is unknown, from the SSRQ-ODD-Schema.
 :
 : @error  ODD-schema part not supported
 :
 : @param  $attribute Current attribute context
 : @param  $use-plural Use the plural value
 : @param  $upper-case transform the result to uppercase
 : @return Translated attribute value
 :)
declare function ec:translate($attribute as attribute()?, $use-plural as xs:boolean, $to-uppercase as xs:boolean) as xs:string? {
    ec:translate($attribute, (), $use-plural, $to-uppercase)
};

(:~
 : Return translation of an attribute value from the SSRQ-ODD-Schema.
 :
 : @error  ODD-schema part not supported
 :
 : @param  $attribute Current attribute context
 : @param  $part The part in the schema
 : @param  $use-plural Use the plural value
 : @param  $upper-case transform the result to uppercase
 : @return Translated attribute value
 :)
declare function ec:translate($attribute as attribute()?, $part as xs:string?, $use-plural as xs:boolean, $to-uppercase as xs:boolean) as xs:string?  {
    (
        let $session-lang := $config:lang-settings?lang
        let $infos := map { "el": local-name($attribute/..), "attr": local-name($attribute), "val": $attribute/string()}
        let $resolved-part := if ($part) then
                                $part
                                else
                                    if ($config:schema-odd//tei:elementSpec[@ident=$infos?el]//tei:attDef[@ident=$infos?attr][tei:datatype]) then
                                        'ssrq.datatypes'
                                    else
                                        'ssrq.elements'

        return
            switch ($resolved-part)
                case 'ssrq.datatypes'
                    return
                        let $valItem := $config:schema-odd//tei:dataSpec//tei:valItem[@ident=$infos?val]
                        return
                            if ($use-plural) then
                                ($valItem/tei:desc[@xml:lang=$session-lang][@type="plural"]/string(), $valItem/tei:desc[@xml:lang=$session-lang][1]/string())[1]
                            else
                                $valItem/tei:desc[@xml:lang=$session-lang][1]/string()
                case 'ssrq.elements'
                    return
                        let $valItem := $config:schema-odd//tei:elementSpec[@ident=$infos?el]//tei:attDef[@ident=$infos?attr]//tei:valItem[@ident=$infos?val]
                        return
                            if ($use-plural) then
                                ($valItem/tei:desc[@xml:lang=$session-lang][@type="plural"]/string(), $valItem/tei:desc[@xml:lang=$session-lang][1]/string())[1]
                            else
                                $valItem/tei:desc[@xml:lang=$session-lang][1]/string()
                default return error(xs:QName("ec:UnsupportedSchemaPart"))
    )[$attribute]
    ! (if (. and $to-uppercase) then upper-case(substring(.,1,1)) || substring(.,2) else .)
};

declare function ec:format-id($id as xs:string?) as xs:string {
    let $doc := ssrq-cache:load-from-static-cache-by-id($config:static-cache-path, $config:static-docs-list, $id)
    return
        if ($doc) then
            ec:print-id($doc)
        else
            let $parsed-idno := idno-parser:parse-regular($id)
            return
                if ($parsed-idno/child::*) then
                    ec:print-id($parsed-idno)
                else
                    $id
};

declare function ec:parse-volume($volume as xs:string) as xs:string {
    (
        let $parts := $volume => tokenize('_')
        for $part at $i in $parts
        return
            if ($i eq $parts => count()) then
                $part
            else
                if ($part => matches('[IVX|0-9]')) then
                    $part || '/'
                else
                    $part ||' '
    ) => string-join('')
};

declare function ec:print-id($doc as element(doc)) as xs:string? {
    (
         $doc/prefix, $doc/kanton,
         $doc/volume => ec:parse-volume(),
         (if ($doc/special) then
            $doc/special
        else
            string-join((string-join(($doc/case, $doc/doc), '.'), $doc/num), '-'))
    )
     => string-join(' ')
};

declare function ec:create-link($components as xs:string*, $params as map(*),
                                $add-lang-param as xs:boolean) as xs:string {
    let $path :=
        string-join($components, "/")
    let $query-params :=
        (
            if ($add-lang-param
                and $config:lang-settings?add-lang-param
                and not($params?lang)) then
                $params => map:put("lang", $config:lang-settings?lang)
            else
                $params
        )
        => map:for-each(function ($k, $v) {
               ($k, $v) => string-join('=')
           })
        => string-join('&amp;')
    return
        $path || ("?" || $query-params)[$query-params]
};

declare function ec:create-link($components as xs:string*, $params as map(*)) as xs:string {
    ec:create-link($components, $params, false())
};

(:~
: Helper function to create links based on the site prefix
:  – the function can be used by other XQuery functions.
:
: in templates use "{app}/..." URLs via ssrq-helper:resolve-links().
:
: @author Bastian Politycki, Dennis Camera
: @return xs:string
:)
declare function ec:create-app-link($components as xs:string*, $params as map(*)) as xs:string {
    ec:create-link((
            $config:base-url,
            if (not(empty($components))) then $components else ''
        ), $params, true())
};

declare function ec:create-app-link($components as xs:string*) as xs:string {
    ec:create-app-link($components, map{})
};

declare function ec:process-urn-ssrq($value as xs:string) as xs:string {
    let $id := $value => substring-after('urn:ssrq:')
    return
        if ($id and $id => matches($ec:prefix)) then
            $id
        else
            error(xs:QName("ec:invalid-urn"), "Invalid SSRQ URN: " || $value)
};

(:~
: A simple wrapper function around ec:craete-app-link() to create links based in IDNOs
: – pages for single documents are always created with '.html' at the end. This is:
: not necessary for links to complete volumes.
:
: @param $id the IDNO of the document
: @return the link as xs:string
:)
declare function ec:create-link-from-id($id as xs:string) as xs:string {
    let $tokenized-id := replace($id, '^(SSRQ|SDS|FDS)-', '') => tokenize('-')
    return
        ($tokenized-id[1], $tokenized-id[2], $tokenized-id[position() = 3 to last()] => string-join('-') || '.html'[$tokenized-id => count() > 2])
        => ec:create-app-link()
};

declare function ec:create-p-link-from-id($id as xs:string) as xs:string {
    ec:create-p-link-from-id($id, false())
};

declare function ec:create-p-link-from-id($id as xs:string, $force as xs:boolean) as xs:string {
    if ($id => matches("^(SSRQ|SDS|FDS)") and ($config:lang-settings?add-lang-param or $config:env/env = 'dev') and not($force)) then
        (: internal links in dev or when the language must be carried :)
        ec:create-link-from-id($id)
    else
        ($config:permalink-base => replace('^(.*?)/?$', '$1'), encode-for-uri($id))
        => string-join("/")
};

declare function ec:prefix-url-with-protocol($url as xs:string) as xs:string {
    if ($url => starts-with('http')) then
        $url
    else
        'https:' || $url
};

declare function ec:format-date($when as xs:string?) {
    ec:format-date($when, $config:lang-settings?lang)
};

declare function ec:format-date($when as xs:string?, $language as xs:string?) {
    if ($when) then
        text {
            try {
                if (matches($when, "^--\d+-\d+")) then
                    format-date(xs:date(replace($when, "^-(.*)$", "1900$1")), "[D1]. [MNn]", $language, (), ())
                else if (matches($when, "^--\d+")) then
                    format-date(xs:date(replace($when, "^-(.*)$", "1900$1-01")), "[MNn]", $language, (), ())
                else if (matches($when, "^\d{4}-\d{2}$")) then
                    format-date($when || '-01', "[MNn] [Y0001]", $language, (), ())
                else if (matches($when, "^\d+$")) then
                    $when
                else
                    if ($language = 'fr') then
                        format-date(xs:date($when), "[D01].[M01].[Y0001]", $language, (), ())
                    else
                        format-date(xs:date($when), "[D1].[M1].[Y0001]", $language, (), ())
            } catch * {
                console:log("Invalid date: " || $when)
            }
        }
    else
        ()
};

declare function ec:format-duration($duration as xs:string) as xs:string {
    try {
        let $parsed-duration := $duration => analyze-string('^P(?:(\d+)?Y)?(?:(\d+)?M)?(?:(\d+)?W)?(?:(\d+)?D)?T?(?:(\d+)?H)?(?:(\d+)?M)?(?:(\d+)?S)?$')
        let $components :=
            (
                ec:get-duration-label("year", $parsed-duration//xpath:group[@nr = '1']),
                ec:get-duration-label("month", $parsed-duration//xpath:group[@nr = '2']),
                ec:get-duration-label("week", $parsed-duration//xpath:group[@nr = '3']),
                ec:get-duration-label("day", $parsed-duration//xpath:group[@nr = '4']),
                ec:get-duration-label("hour", $parsed-duration//xpath:group[@nr = '5']),
                ec:get-duration-label("minute", $parsed-duration//xpath:group[@nr = '6'])
            )
        return
            string-join(
                (
                for $component in $components
                let $key := $component => map:keys()
                let $value := $component($key)
                return
                    ($value || " " || $key)[$value > 0]
                ), " "
            )
    } catch * {
        $duration
    }
};

declare function ec:get-duration-label($name as xs:string, $quantity as xs:int?) as map(*) {
    let $lang := $config:lang-settings?lang
    let $val := $config:translations//tei:dataSpec[@ident='ssrq.labels']//tei:valItem[@ident=$name]
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

declare function ec:footnote-label($nr as xs:int) {
    string-join(reverse(ec:footnote-label-recursive($nr)))
};

declare function ec:existsAdditionalSource($idno as xs:string) {
    if (matches($idno, "_1$")) then
        true()
    else
        false()
};

declare function ec:additionalSource($idno as xs:string) {
    let $base := replace($idno, "^(.*)_1$", '$1')
    for $header in
        collection($config:data-root)//tei:teiHeader[matches(.//tei:seriesStmt/tei:idno, "^" || $base || "_\d+$")]
            [not(.//tei:seriesStmt/tei:idno = $idno)]
        order by number(replace($header//tei:seriesStmt/tei:idno, "^.*_(\d+)$", "$1"))
        return
            $header//tei:msDesc
};

declare function ec:url($url as xs:string) {
    (: fix URL for LaTeX :)
    let $url := tokenize(functx:replace-multi($url, ('#', '%'), ('\\#', '\\%')))[1]

    return '\url{' || $url || '}'
};

declare function ec:format-ssrq-author($author as node()*) {

    if (count($author) > 2) then
        $author[1]/text() || ', ' || $author[2]/text() || ' ' || ec:label('and', false()) || ' ' || $author[3]/text()
    else if (count($author) = 2) then
        $author[1]/text() || ' ' || ec:label('and', false()) || ' ' || $author[2]/text()
    else
        $author[1]/text()
};

declare function ec:format-author($author as node()*) {
    (: save typing in ssrq.odd, used in biblStruct :)

    if ($author) then
        if (count($author) > 2) then
            string-join(($author[1], $author[2]), ec:semicolon()) || ' et al.'
        else
            string-join($author, ec:semicolon())
    else
        ()
};

declare function ec:switch-name($name as node()*) {
    if ($name => contains(', ')) then
    substring-after($name, ', ') || ' ' || substring-before($name, ', ')
    else $name
};

declare function ec:format-editor($editors as node()*) {
    let $count := $editors => count()
    return
        if ($editors) then
            if ($count > 2 or $editors[last()] => matches('et[\.]?\sal')) then
                ($editors !
                (if(not(. => matches('et[\.]?\sal')) and (position() <= 2)) then ec:switch-name(.) else()))
                 => string-join(', ') || ' et al.'
            else if ($count = 2) then
                ($editors ! ec:switch-name(.)) => string-join(' ' || ec:label('and', false()) || ' ')
            else
                ec:switch-name($editors)
        else
            ()
};

declare function ec:print-date($date as node()*) {
    (: save typing in ssrq.odd :)
    let $lang := $config:lang-settings?lang
    let $date-string :=
        if ($date/@when) then
          if (matches($date/@when, "^\d{4}-\d{2}$")) then
            format-date(xs:date($date/@when || '-01'), "[MNn] [Y0001]", $lang, (), ())
          else
            format-date(xs:date($date/@when), '[Y] [MNn] [D1]', $lang, (), ())
        else if (matches($date/@from, '-01-01$') and matches($date/@to, '-12-31$')) then (: precision is one year :)
            if (substring($date/@from, 1, 4) = substring($date/@to, 1, 4)) then
                substring($date/@from, 1, 4)
            else
                ec:print-date-period(xs:int(substring($date/@from, 1, 4)), xs:int(substring($date/@to, 1, 4)))
        else if (substring($date/@from, 1, 4) = substring($date/@to, 1, 4)) then (: within the same year :)
            if (substring($date/@from, 6, 2) = substring($date/@to, 6, 2)) then (: within the same month :)
                format-date(xs:date($date/@from), '[Y] [MNn] [D1]', $lang, (), ()) || ' – ' || format-date(xs:date($date/@to), '[D1]')
            else
                format-date(xs:date($date/@from), '[Y] [MNn] [D1]', $lang, (), ()) || ' – ' || format-date(xs:date($date/@to), '[MNn] [D1]', $lang, (), ())
        else
            string-join((format-date(xs:date($date/@from), '[Y] [MNn] [D1]', $lang, (), ()),
            ' – ',
            format-date(xs:date($date/@to), '[Y] [MNn] [D1]', $lang, (), ())))
    let $old-style :=
        if ($date/@calendar='Julian') then
            ' ' || ec:label('old-style-abbr', false())
        else
            ()

    return $date-string || $old-style
};

declare function ec:print-date-period($from as xs:int, $to as xs:int) {
    let $century := $from idiv 100 + 1
    let $default := string-join(('ca. ', $from, ' – ', $to))
    return
        if (($to - $from = 99) and ($to mod 100 = 0)) then
            string-join(($century, ec:label('century-ordinal', false()), ' ', ec:label('century-abbr', false())))
        else if (($to - $from = 49) and ($to mod 50 = 0)) then
            switch ($to - $from idiv 100 * 100)
                case  50 return string-join((ec:label('first-female', false()), ' ', ec:label('half-cent-abbr', false()), ' ', $century, ec:label('century-ordinal', false()), ' ', ec:label('century-abbr', false())))
                case 100 return string-join((ec:label('second-female', false()), ' ', ec:label('half-cent-abbr', false()), ' ', $century, ec:label('century-ordinal', false()), ' ', ec:label('century-abbr', false())))
                default return $default
        else if (($to - $from = 24) and ($to mod 25 = 0)) then
            switch ($to - $from idiv 100 * 100)
                case  25 return string-join((ec:label('first-male', false()), ' ', ec:label('quarter-cent-abbr', false()), ' ', $century, ec:label('century-ordinal', false()), ' ', ec:label('century-abbr', false())))
                case  50 return string-join((ec:label('second-male', false()), ' ', ec:label('quarter-cent-abbr', false()), ' ', $century, ec:label('century-ordinal', false()), ' ', ec:label('century-abbr', false())))
                case  75 return string-join((ec:label('third-male', false()), ' ', ec:label('quarter-cent-abbr', false()), ' ', $century, ec:label('century-ordinal', false()), ' ', ec:label('century-abbr', false())))
                case 100 return string-join((ec:label('fourth-male', false()), ' ', ec:label('quarter-cent-abbr', false()), ' ', $century, ec:label('century-ordinal', false()), ' ', ec:label('century-abbr', false())))
                default return $default
        else if (($to - $from = 20) and ($from mod 100 = 40)) then
            string-join((ec:label('mid-cent-abbr', false()), ' ', $century, '. ', ec:label('century-abbr', false())))
        else
            $default
};

declare %private function ec:footnote-label-recursive($nr as xs:int) {
    if ($nr > 0) then
        let $nr := $nr - 1
        return (
            codepoints-to-string(string-to-codepoints("a") + $nr mod 26),
            ec:footnote-label-recursive($nr div 26)
        )
    else
        ()
};

declare function ec:persName-list($names as element(tei:persName)*) {
    if (count($names) > 1) then (
        string-join(subsequence($names, 1, count($names) -1), ', '),
        <i18n:text key="and"> und </i18n:text>,
        $names[last()]
    ) else
        $names
};

declare function ec:unique-id($node as node()) as xs:string {
    util:node-id($node)
};

declare function ec:image($config as map(*), $node as element(), $class as xs:string+, $content as node()*) as element()+ {
    let $collection-name := utils:path-concat-safe((util:collection-name($node), 'assets'))
    return
        switch ($node/tei:graphic/@mimeType)
        case 'image/svg'
            return
                let $svg := doc(utils:path-concat-safe(($collection-name, $node/tei:graphic/@url/data(.))))
                return
                    if ($svg)
                    then
                        <div class="svg-container">
                                {$svg}
                                {   let $head := $node/tei:head
                                    where $head
                                    return
                                        <p class="svg-container__title">{$head/text()}</p>
                                }
                        </div>
                    else <p>Sorry, could not load SVG</p>
        case 'image/jpg'
            return
                (
                    <img src="{
                        ($collection-name => replace($config:data-root, $config:base-url), $node/tei:graphic/@url)
                        => string-join('/')
                    }" alt="{$node/tei:graphic/@url}" class="image-in-text"/>,
                    let $head := $node/tei:head
                    where $head
                    return
                        <p class="img__title">{$head/text()}</p>
                )
        default return <p>MimeType {$node/@mimeType} is not supported</p>
};

(:~
: Extract informations from a reference to a manuscript
: in a first place this functions is used in the context of
: so called "cases" (e.g. FR I_2_8)
:
: @param $ref the reference to a manuscript
: @return a string with the informations
:)
declare function ec:short-doc-info($ref as element(tei:ref)) as xs:string {
    try {
        let $idno := ec:process-urn-ssrq($ref/@target)
        let $doc := doc(utils:path-concat-safe((util:collection-name($ref), $idno || '.xml')))
        let $head := ec:get-head($doc//tei:sourceDesc/tei:msDesc)/text()
        let $date := $doc//tei:teiHeader//tei:origDate => ec:print-date()
        return $head || ', ' || $date || ' (' || ($ref/text(), ec:format-id($idno))[1] || ')'
    } catch * {
        (
            console:log(($err:code, $err:description, $err:value)),
            $ref/text()
        )[1]
    }
};

(:~
: Format the link of an external literature-reference
:
: @param $id the external id
: @return the formated url as a string
:
:)
declare function ec:format-link($id as xs:string*) as xs:string* {
    let $link-base := map {
        "national-bib": "http://permalink.snl.ch/bib/",
        "ssrq-old": "https://www.ssrq-sds-fds.ch/online/"
    }
    let $ssrq-names := ('SDS', 'SSRQ', 'FDS')
    return
        if ($id => contains('bsg') or $id => contains('sz'))
        then
            $link-base?national-bib || $id
        else
            if (some $name in $ssrq-names satisfies $id => contains($name))
            then
                let $volume := $id => substring-after('_')
                let $collection := $volume => substring-before ('_')
                return
                    if (utils:path-concat-safe(($config:data-root, $collection, $volume)) => xmldb:collection-available())
                    then
                        ec:create-app-link(($collection, $volume, ''))
                    else
                        $link-base?ssrq-old || $volume
            else ()
};



declare function ec:render-title-with-hi($title as node()*, $mode as xs:string) {
    let $titleRendition :=
    for $node in $title
    return
        typeswitch($node)
            case element(tei:title)
                return
                    ec:render-title-with-hi($node/node(), $mode)
            case element(tei:hi)
                return
                    if ($mode = 'web')
                    then
                        switch ($node/@rend/data(.))
                            case 'sup'
                                return
                                    <sup>{ec:render-title-with-hi($node/node(), $mode)}</sup>
                            case 'sub'
                                return
                                    <sub>{ec:render-title-with-hi($node/node(), $mode)}</sub>
                            case 'italic'
                                return
                                    <span class="is-italic">{ec:render-title-with-hi($node/node(), $mode)}</span>
                            default return
                                    <span>{ec:render-title-with-hi($node/node(), $mode)}</span>
                    else
                        switch ($node/@rend/data(.))
                            case 'sup'
                                return
                                   '\lss{' || ec:render-title-with-hi($node/node(), $mode) || '}'
                            case 'sub'
                                return
                                   '\textsubscript{' || ec:render-title-with-hi($node/node(), $mode) || '}'
                            case 'italic'
                                return
                                    '\textit{' || ec:render-title-with-hi($node/node(), $mode) || '}'
                            default return
                                    ec:render-title-with-hi($node/node(), $mode)
            case text()
                return
                    $node => replace(' : ', ' – ')
            default return
                ()
    return $titleRendition
};


declare function ec:parse-biblScope($node as node(), $part as xs:string) as xs:string? {
    if ($node//tei:biblScope => count() < 2 and $node//tei:pubPlace) then
        switch($part)
            case 'series'
                return
                    if($node/tei:monogr/tei:imprint and $node/tei:monogr/tei:imprint/tei:biblScope[1] => string-length() > 0 and $node/tei:monogr/tei:imprint/tei:biblScope[1] => contains(',')) then
                        ' ' || ec:join-series($node/tei:monogr/tei:imprint/tei:biblScope)
                    else if ($node/tei:monogr/tei:biblScope and $node/tei:monogr/tei:biblScope[1] => string-length() > 0 and $node/tei:monogr/tei:biblScope[1] => contains(',')) then
                        ' ' || ec:join-series($node/tei:monogr/tei:biblScope)
                    else ()
            case 'scope'
                return
                    if ($node/tei:monogr/tei:imprint and $node/tei:monogr/tei:imprint/tei:biblScope[1] => string-length() > 0) then
                        ', ' || ec:join-scopes($node/tei:monogr/tei:imprint/tei:biblScope)
                    else if ($node/tei:monogr/tei:biblScope and $node/tei:monogr/tei:biblScope[1] => string-length() > 0) then
                        ', ' || ec:join-scopes($node/tei:monogr/tei:biblScope)
                    else ()
            default return ()
    else if ($part = 'series') then
        ' ' || ($node//tei:biblScope !  (.=> replace('[S|p]\.', ec:label('page-abbr', false())))) => string-join('; ')
    else ()
};

declare function ec:join-series($series as node()*) as xs:string {
    let $strings := $series ! (. => replace(',?\s?[S|p]\.\s?\d*.?\d*.*', ''))
    return
        $strings => string-join('; ')
};

declare function ec:join-scopes($scopes as node()*) as xs:string {
    let $strings := $scopes ! (if (. => matches('[S|p|P]\.')) then
                                ec:label('page-abbr', false()) || ' ' || . => replace('^.*[S|p]\. ([0-9]*-?[0-9]*.*)', '$1')
                                else .
                              )
    return
        $strings => string-join('; ')
};

declare function ec:join-series-with-scope($series as node()*) as xs:string  {
    ($series ! ((./tei:title, ./tei:biblScope) => string-join(' ')))
     => string-join('; ') || ', '
};

(:
: A simple helper function to get the correct tei:head-element
: depending on the selected session language
:
: @param $msDesc the surrounding tei:msDesc-Element
: @return the tei:head to render
:)
declare function ec:get-head($msDesc as element()) as element(tei:head) {
    if ($msDesc/tei:head[@xml:lang]) then
        let $lang := $config:lang-settings?lang
        return
            if ($msDesc/tei:head[@xml:lang = $lang]) then
                $msDesc/tei:head[@xml:lang = $lang]
            else
                $msDesc/tei:head[@xml:lang][1]
    else
        $msDesc/tei:head
};

(:~
: A wrapper to retrive information about a document using the parsed idno
: this function can be used in odd models
:
: @author: Bastian Politycki
: @date: 2022-11-03
:
: @param $idno as xs:string
: @return the parsed idno as element(doc)
:)

declare function ec:doc-infos($idno as xs:string) as map(*)? {
    let $idno-doc := ssrq-cache:load-from-static-cache-by-id($config:static-cache-path, $config:static-docs-list, $idno)
    let $main := if ($idno-doc/case => exists() and number($idno-doc/doc) eq 0) then
                    true()
                else if ($idno-doc/case => empty()) then
                    true()
                else false()
    return
    if ($idno-doc => exists()) then
        map {
            "result": $idno-doc,
            "is-main-case": $main,
            "article-nr": number(if ($main and $idno-doc/case => exists()) then $idno-doc/case else $idno-doc/doc/text())
        }
    else
        error(xs:QName('ec:common'), 'Failed to parse idno: ' || $idno)

};
