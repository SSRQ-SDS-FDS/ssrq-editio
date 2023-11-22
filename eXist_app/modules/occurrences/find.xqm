xquery version "3.1";

module namespace occurrences-find="http://ssrq-sds-fds.ch/exist/apps/ssrq/occurrences/find";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~ Find all keywords in a
: given corpus of TEI-XML-documents
:
: @param $docs The corpus of TEI-XML-documents
: @return A sequence of strings containing the ids of all keywords
:)
declare function occurrences-find:keywords($docs as element(tei:TEI)+) as xs:string+ {
    for $keyword-key in $docs//tei:term[starts-with(@ref, 'key')]/@ref
    group by $keyword-key
    order by $keyword-key
    return $keyword-key
};

(:~ Find all lemmata in a
: given corpus of TEI-XML-documents
:
: @param $docs The corpus of TEI-XML-documents
: @return A sequence of strings containing the ids of all lemmata
:)
declare function occurrences-find:lemmata($docs as element(tei:TEI)+) as xs:string+ {
    for $lem-key in $docs//tei:term[starts-with(@ref, 'lem')]/@ref
    group by $lem-key
    order by $lem-key
    return $lem-key
};

(:~ Find all persons in a
: given corpus of TEI-XML-documents
:
: @param $docs The corpus of TEI-XML-documents
: @return A sequence of strings containing the ids of all persons
:)
declare function occurrences-find:persons($docs as element(tei:TEI)+) as xs:string+ {
    for $person-key in $docs//tei:persName/@ref | $docs//@scribe[starts-with(., 'per')]
    group by $person-key
    order by $person-key
    return $person-key
};

(:~ Find all places in a
: given corpus of TEI-XML-documents
:
: @param $docs The corpus of TEI-XML-documents
: @return A sequence of strings containing the ids of all places
:)
declare function occurrences-find:places($docs as element(tei:TEI)+) as xs:string+ {
    for $loc-key in $docs//(tei:placeName[@ref]/@ref|tei:origPlace[@ref]/@ref)
    group by $loc-key
    order by $loc-key
    return $loc-key
};
