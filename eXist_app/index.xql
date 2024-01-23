xquery version "3.1";

module namespace index="http://ssrq-sds-fds.ch/exist/apps/ssrq/query/index";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xpath = 'http://www.w3.org/2005/xpath-functions';

(:~
: This module contains utility functions for
: the database index
:)

(:~
: Extracts the title of an article
: and returns the value as a string for
: indexing purposes. Ignores any notes.
:
: @param $doc The document to extract the title from
: @return The title of the document
:)
declare function index:get-title($doc as element(tei:TEI)) as xs:string* {
    ($doc//tei:msDesc)[1]/tei:head !
    .//text()[not(parent::tei:note)]
    => string-join(' ')
    => replace('\s+', ' ')
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
declare function index:parse-idno($input as item(), $check-is-main as xs:boolean) as map(*) {
    let $idno :=
        typeswitch($input)
            case xs:string return
                $input
            case element(tei:TEI) return
                $input//tei:seriesStmt/tei:idno[1]
            default return
                error((), 'The input must be either a TEI-XML document or a string')
    let $parse-case-part := function ($group as element(xpath:group)) as element()* {
        for $i in tokenize($group/text(), '\.')
        return
            (
                <case>{$i}</case>[matches($i, '^\d+$')],
                <opening>{$i}</opening>[matches($i, '^[A-Za-z]+$')]
            )[1]
    }
    let $group-handler := function ($group as element(xpath:group)) as element()* {
        switch ($group/@nr)
            case '1' return <prefix>{$group/text()}</prefix>
            case '2' return <kanton>{$group/text()}</kanton>
            case '3' return <volume>{$group/text()}</volume>
            case '4' return $parse-case-part($group)
            case '5' return <doc>{$group/text()}</doc>
            case '6' return <num>{$group/text()}</num>
            case '7' return <special>{$group/text()}</special>
            default return ()
    }
    let $doc-info as element(doc) :=
        <doc xml:id="{$idno}">
            {
        for $group in (analyze-string($idno, '^(SSRQ|SDS|FDS)
                                -([A-Z]{2})
                                -([A-Za-z0-9_]+)
                                -(?:((?:[A-Za-z0-9]+\.)*)([0-9]+)
                                -([0-9]+)|([a-z]{3,}))$', 'x'))//xpath:group
            return
                $group-handler($group)
            }
        </doc>
    let $sort-key := xs:integer(($doc-info/case | $doc-info/doc)[1])
    return
        if ($check-is-main) then
            map {
                'doc-info': $doc-info,
                'is-main':  exists($doc-info[not(special)][not(opening)][not(case)][num eq '1'] | $doc-info[not(special)][not(opening)][case][doc eq '0'][num eq '1']),
                'sort-key': $sort-key
            }
        else
            map {
                'doc-info': $doc-info,
                'sort-key': $sort-key
            }
};

(:~
: Creates a human readable string from an IDNO.
:
: @param $input The document to check – can be either
: a TEI-XML document or the IDNO as xs:string
: @return The parsed idno as xs:string
:)
declare function index:idno-print($input as xs:string) as xs:string {
    let $idno :=
        typeswitch($input)
            case xs:string return
                $input
            default return
                $input//tei:seriesStmt/tei:idno[1]
    let $print-volume :=
        function ($volume as xs:string) as xs:string {
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
        }
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
                            $print-volume($part)
                        else if ($index = $len-idno-parts) then
                            (: -1 will be stripped :)
                            ()
                        else
                            $part
                , ' ')
};
