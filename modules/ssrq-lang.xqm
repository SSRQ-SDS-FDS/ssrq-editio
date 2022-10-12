xquery version "3.1";

module namespace ssrq-lang="http://ssrq-sds-fds.ch/exist/apps/ssrq/lang";

import module namespace request="http://exist-db.org/xquery/request";

declare variable $ssrq-lang:fallback := "de";

declare variable $ssrq-lang:supported-languages := ("de", "fr", "en", "it");

(:
: A more or less simple solution to set the default language
: adapted from https://jaketrent.com/post/xquery-browser-language-detection/
:
:)
declare function ssrq-lang:get-browser-lang() as xs:string {
  let $header := request:get-header("Accept-Language")
  return if (exists($header)) then
    ssrq-lang:get-top-supported-lang(ssrq-lang:get-browser-langs($header), $ssrq-lang:supported-languages)
  else
    $ssrq-lang:fallback
};

declare function ssrq-lang:get-top-supported-lang($ordered-langs as xs:string*, $translations as xs:string*) as xs:string {
  if (empty($ordered-langs)) then
    $ssrq-lang:fallback
  else
    let $lang := $ordered-langs[1]
    return
      if ($lang = $translations) then
        $lang
      else
        ssrq-lang:get-top-supported-lang(subsequence($ordered-langs, 2), $translations)
};

declare %private function ssrq-lang:get-browser-langs($header as xs:string) as xs:string* {
  for $entry in ssrq-lang:parse-header($header)
  let $data := tokenize($entry, ";q=")
  let $quality := $data[2]
  order by
    if (exists($quality) and string-length($quality) gt 0) then
      xs:float($quality)
    else
      xs:float(1.0)
  descending
  return $data[1]
};

declare %private function ssrq-lang:parse-header($header as xs:string) as xs:string* {
  let $regex := "^(([a-z]{1,8})(-[a-z]{1,8})?)\s*(;\s*q\s*=\s*(1|1\.0{0,3}|0\.[0-9]{0,3}))?$"
  let $format := "$2;q=$5"
  for $lang in tokenize($header, ",")
  where $lang => matches($regex, "i")
  return
       replace($lang, $regex, $format, "i")
};

declare function ssrq-lang:get-lang-settings() as map(*) {
    let $site-lang := request:get-header("X-Site-Lang")
    let $req-lang := request:get-parameter("lang", "")
    return
        map {
            "add-lang-param": $site-lang => empty(),
            "lang": 
              if ($site-lang = $ssrq-lang:supported-languages) then
                $site-lang
              else if ($req-lang = $ssrq-lang:supported-languages) then
                $req-lang
              else
                ssrq-lang:get-browser-lang()
        }
};
