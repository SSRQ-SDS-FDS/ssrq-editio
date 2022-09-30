xquery version "3.1";

module namespace ssrq-lang="http://ssrq-sds-fds.ch/exist/apps/ssrq/lang";

import module namespace request="http://exist-db.org/xquery/request";

declare variable $ssrq-lang:fallback := "de";

(:
: A more or less simple solution to set the default language
: adapted from https://jaketrent.com/post/xquery-browser-language-detection/
:
:)
declare function ssrq-lang:get-browser-lang() as xs:string {
  let $header := request:get-header("Accept-Language")
  return if (exists($header)) then
    ssrq-lang:get-top-supported-lang(ssrq-lang:get-browser-langs($header), ("de", "fr", "en", "it"))
  else
    $ssrq-lang:fallback
};

declare function ssrq-lang:get-top-supported-lang($ordered-langs as xs:string*, $translations as xs:string*) as xs:string {
  if (empty($ordered-langs)) then
    $ssrq-lang:fallback
  else
    let $lang := $ordered-langs[1]
    return if ($lang = $translations) then
      $lang
    else
      ssrq-lang:get-top-supported-lang(subsequence($ordered-langs, 2), $translations)
};

declare %private function ssrq-lang:get-browser-langs($header as xs:string) as xs:string* {
  let $langs :=
    for $entry in tokenize(ssrq-lang:parse-header($header), ",")
    let $data := tokenize($entry, "q=")
    let $quality := $data[2]
    order by
      if (exists($quality) and string-length($quality) gt 0) then
        xs:float($quality)
      else
        xs:float(1.0)
    descending
    return $data[1]
  return $langs
};

declare %private function ssrq-lang:parse-header($header as xs:string) as xs:string {
  let $regex := "(([a-z]{1,8})(-[a-z]{1,8})?)\s*(;\s*q\s*=\s*(1|0\.[0-9]+))?"
  let $flags := "i"
  let $format := "$2q=$5"
  return replace(lower-case($header), $regex, $format)
};

declare function ssrq-lang:check-x-site-lang() as map(*) {
    let $header := request:get-header("X-Site-Lang")
    return
        map {
            "add-lang-param": $header => empty() ,
            "lang": $header
        }
};
