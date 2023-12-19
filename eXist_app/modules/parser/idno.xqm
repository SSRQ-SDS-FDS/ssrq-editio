xquery version "3.1";

module namespace idno-parser="http://ssrq-sds-fds.ch/exist/apps/ssrq/parser/idno";

import module namespace index="http://ssrq-sds-fds.ch/exist/apps/ssrq/query/index" at "../../index.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xpath = 'http://www.w3.org/2005/xpath-functions';

(:~
: Parses an SSRQ idno and returns an structured
: XML element.
:
: @param $idno The idno to parse as xs:string
: @return The parsed idno as element (doc)
:)
declare function idno-parser:parse-regular($idno as xs:string) as element(doc) {
    idno-parser:parse($idno, false())?doc-info
};

(:~
: This will parse an IDNO and return
: structured information as a XML element.
: Furthermore it can also check (by the IDNO), if
: a document is a main article (not part of a case) or
: not.
: Note: This function is self-contained and can be used
: without the rest of the module. It can't be splitted
: into smaller parts, because it's used by the DB-index
: to process field-values.
:
: @param $input The document to check – can be either
: a TEI-XML document or the IDNO as xs:string
: @param check-is-main as xs:boolean – If true, the function
: will check if the document is a main article or not
: @return map(*) – The parsed IDNO as element (doc) and
: if check-is-main is true, the map will also contain
: a boolean value with the key 'is-main'. Furthermore
: the map will contain the key 'sort-key' with
: a key as xs:integer to sort the documents by.
:)
declare function idno-parser:parse($input as item(), $check-is-main as xs:boolean) as map(*) {
    index:parse-idno($input, $check-is-main)
};

(:~
: Creates a human readable string from an IDNO.
:
: @param $input The document to check – can be either
: a TEI-XML document or the IDNO as xs:string
: @return The parsed idno as xs:string
:)
declare function idno-parser:print($input as xs:string) as xs:string {
    index:idno-print($input)
};

(:
: Creates a human readable string from an volume name.
:
: @param $volume The volume name as xs:string
: @return The parsed volume name as xs:string
:)
declare function idno-parser:print-volume($volume as xs:string) as xs:string {
    let $parts := tokenize($volume, '_')
    let $len := count($parts)
    return string-join(
            for $part at $i in $parts
            return
                if ($part => matches('[IVX0-9]+')) then
                    ($part, '/'[$i ne $len])
                else
                    ($part, ' '[$i ne $len])
            )
};
