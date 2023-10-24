xquery version "3.1";

module namespace date-parser="http://ssrq-sds-fds.ch/exist/apps/ssrq/parser/date";

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
