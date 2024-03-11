xquery version "3.1";

module namespace idno-parser="http://ssrq-sds-fds.ch/exist/apps/ssrq/parser/idno";

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
    idno-parser:parse($idno)
};

(:~
: This will parse an IDNO and return
: structured information as a XML element.
: Furthermore it can also check (by the IDNO), if
: a document is a main article (not part of a case) or
: not.
:
: @param $input The document to check – can be either
: a TEI-XML document or the IDNO as xs:string
: @return The parsed idno / document as element (doc)
:)
declare function idno-parser:parse($input as item()) as element(doc) {
     let $idno :=
        typeswitch($input)
            case xs:string return
                $input
            case element(tei:TEI) return
                $input//tei:seriesStmt/tei:idno[1]
            default return
                error((), 'The input must be either a TEI-XML document or a string')
    let $doc-info as element(doc) :=
        <doc xml:id="{$idno}" printed-idno="{idno-parser:print($idno)}">
            {
                for $group in (analyze-string($idno, '^(SSRQ|SDS|FDS)
                                        -([A-Z]{2})
                                        -([A-Za-z0-9_]+)
                                        -(?:((?:[A-Za-z0-9]+\.)*)([0-9]+)
                                        -([0-9]+)|([a-z]{3,}))$', 'x'))//xpath:group
                return
                    idno-parser:part-to-info($group)
            }
        </doc>
    return
        $doc-info
        => idno-parser:add-sort-key-as-attribute()
        => idno-parser:add-main-check-as-attribute()
};

(:~
: Creates a human readable string from an IDNO.
:
: @param $input The document to check – can be either
: a TEI-XML document or the IDNO as xs:string
: @return The parsed idno as xs:string
:)
declare function idno-parser:print($input as xs:string) as xs:string {
    let $idno :=
        typeswitch($input)
            case xs:string return
                $input
            default return
                $input//tei:seriesStmt/tei:idno[1]
    return
        if ($idno instance of element(tei:idno) and $idno[@type]) then
            $idno
        else
            let $idno-parts := tokenize($idno, '-')
            let $len-idno-parts := count($idno-parts)
            return
                string-join(
                    for $part at $index in tokenize($idno, "-")
                    return
                        if ($index = 3) then
                            idno-parser:print-volume($part)
                        else if ($index = $len-idno-parts) then
                            (: -1 will be stripped :)
                            ()
                        else
                            $part
                , ' ')
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


declare %private function idno-parser:part-to-info($group as element(xpath:group)) as element()* {
    switch ($group/@nr)
        case '1' return <prefix>{$group/text()}</prefix>
        case '2' return <kanton>{$group/text()}</kanton>
        case '3' return <volume>{$group/text()}</volume>
        case '4' return idno-parser:parse-case-part($group)
        case '5' return <doc>{$group/text()}</doc>
        case '6' return <num>{$group/text()}</num>
        case '7' return <special>{$group/text()}</special>
        default return ()
};

declare %private function idno-parser:parse-case-part($group as element(xpath:group)) as element()* {
    for $i in tokenize($group/text(), '\.')
    return
        (
            <case>{$i}</case>[matches($i, '^\d+$')],
            <opening>{$i}</opening>[matches($i, '^[A-Za-z]+$')]
        )[1]
};

declare %private function idno-parser:add-sort-key-as-attribute($doc-info as element(doc)) as element(doc) {
    let $sort-key := xs:integer(($doc-info/case | $doc-info/doc)[1])
    return
        element doc {
            $doc-info/@*,
            attribute sort-key { $sort-key },
            $doc-info/node()
        }
};

declare %private function idno-parser:add-main-check-as-attribute($doc-info as element(doc)) as element(doc) {
    let $is-main := exists(
                        $doc-info[not(special)][not(opening)][not(case)][num eq '1'] |
                        $doc-info[not(special)][not(opening)][case][doc eq '0'][num eq '1']
                    )
    return
        element doc {
            $doc-info/@*,
            attribute is-main { $is-main },
            $doc-info/node()
        }
};
