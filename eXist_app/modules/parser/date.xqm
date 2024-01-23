xquery version "3.1";

module namespace date-parser="http://ssrq-sds-fds.ch/exist/apps/ssrq/parser/date";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common" at "../ext-common.xqm";
import module namespace logger="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils/logger" at "../utils/logger.xqm";

(:~
: Parses an SSRQ idno and returns an structured
: XML element.
:
: @param $idno The idno to parse as xs:string
: @return The parsed idno as element (doc)
:)
declare function date-parser:extract-year($date as attribute()) as xs:integer? {
    if (matches($date, '^\d{4}$')) then
        xs:integer($date)
    else
        try {
                year-from-date(xs:date($date))
            }
        catch * {
                logger:log-and-raise-error(
                    string-join(
                        (
                            "Could not extract year from:", $date, "in", document-uri(root($date)),
                            ' '
                        )
                    )
                )
        }
};

(:
: Parses an element with a dating attributes
: and returns a readable version of the date
:
: @param $date The date to parse as element
: @return The parsed date as xs:string
:)
declare function date-parser:print($date as element()*) as xs:string {
    date-parser:print($date, $config:lang-settings?lang)
};

(:
: Parses an element with a dating attributes
: and returns a readable version of the date
:
: @param $date The date to parse as element
: @param $lang The language to use as xs:string
: @return The parsed date as xs:string
:)
declare function date-parser:print($date as element(), $lang as xs:string) as xs:string {
    let $when-custom as attribute(when-custom)? := $date/@when-custom
    let $from-custom as attribute(from-custom)? := $date/@from-custom
    let $to-custom as attribute(to-custom)? := $date/@to-custom
    let $date-string :=
        if ($when-custom) then
            date-parser:format-as-year-month-day($when-custom, $lang)
        else if (matches($from-custom, '-01-01$') and matches($to-custom, '-12-31$')) then (: precision is one year :)
            if (substring($from-custom, 1, 4) = substring($to-custom, 1, 4)) then
                substring($from-custom, 1, 4)
            else
                ec:print-date-period(xs:int(substring($from-custom, 1, 4)), xs:int(substring($to-custom, 1, 4)))
        else if (substring($from-custom, 1, 4) = substring($to-custom, 1, 4)) then (: within the same year :)
            if (substring($from-custom, 6, 2) = substring($to-custom, 6, 2)) then (: within the same month :)
                date-parser:format-as-year-month-day($from-custom, $lang) || ' – ' || format-date(xs:date($to-custom), '[D1]')
            else
                date-parser:format-as-year-month-day($from-custom, $lang) || ' – ' || format-date(xs:date($to-custom), '[MNn] [D1]', $lang, (), ())
        else
            date-parser:format-as-year-month-day($from-custom, $lang) || ' – ' || date-parser:format-as-year-month-day($to-custom, $lang)
    let $old-style :=
        if (date-parser:is-julian($date)) then
            ec:label('old-style-abbr', false())
        else
            ()
    return string-join(($date-string, $old-style), ' ')
};

(:
: Formats a date as year-month-day
:
: @param $date The date to format as attribute
: @return The formatted date as xs:string
:)
declare function date-parser:format-as-year-month-day($date as attribute(), $lang as xs:string) as xs:string {
    format-date(xs:date($date), '[Y] [MNn] [D1]', $lang, (), ())
};

(:
: Checks if the date is in the Julian calendar
:
: @param $date The date to check as element
: @return True if the date is in the Julian calendar
:)
declare function date-parser:is-julian($date as element()) as xs:boolean {
    $date/@calendar => starts-with('julian')
};
