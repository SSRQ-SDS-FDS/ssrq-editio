xquery version "3.1";

module namespace i18n-settings="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/settings";

import module namespace request="http://exist-db.org/xquery/request";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";

(:
: A more or less simple solution to set the default language
: adapted from https://jaketrent.com/post/xquery-browser-language-detection/
:
:)
declare function i18n-settings:get-browser-lang() as xs:string {
  let $header := request:get-header("Accept-Language")
  return if (exists($header)) then
    i18n-settings:get-top-supported-lang(i18n-settings:get-browser-langs($header), $config:i18n-supported-languages)
  else
    $config:i18n-default-lang
};

declare function i18n-settings:get-top-supported-lang($ordered-langs as xs:string*, $translations as xs:string*) as xs:string {
  if (empty($ordered-langs)) then
    $config:i18n-default-lang
  else
    let $lang := $ordered-langs[1]
    return
      if ($lang = $translations) then
        $lang
      else
        i18n-settings:get-top-supported-lang(subsequence($ordered-langs, 2), $translations)
};

declare %private function i18n-settings:get-browser-langs($header as xs:string) as xs:string* {
  for $entry in i18n-settings:parse-header($header)
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

declare %private function i18n-settings:parse-header($header as xs:string) as xs:string* {
  let $regex := "^(([a-z]{1,8})(-[a-z]{1,8})?)\s*(;\s*q\s*=\s*(1|1\.0{0,3}|0\.[0-9]{0,3}))?$"
  let $format := "$2;q=$5"
  for $lang in tokenize($header, ",")
  where $lang => matches($regex, "i")
  return
       replace($lang, $regex, $format, "i")
};

declare function i18n-settings:get-lang-settings() as map(*) {
    let $site-lang := request:get-header("X-Site-Lang")
    let $req-lang := request:get-parameter("lang", "")
    return
        map {
            "add-lang-param": $site-lang => empty(),
            "lang":
              if ($site-lang = $config:i18n-supported-languages) then
                $site-lang
              else if ($req-lang = $config:i18n-supported-languages) then
                $req-lang
              else
                i18n-settings:get-browser-lang()
        }
};

(:
: Get the language set in the request / the application
: from the model using the param-resolver
: or using the default configuration
:
: @param $model the model as map(*)
: @return the language as xs:string
:)
declare function i18n-settings:get-lang-from-model-or-config($model as map(*)) as xs:string {
    let $lang := try { $model?configuration?param-resolver('lang') } catch * { () }
    return
        if (exists($lang)) then
            $lang
        else
            $config:lang-settings?lang
};
