xquery version "3.1";

module namespace pxml="http://ssrq-sds-fds.ch/exist/apps/ssrq/processing/xml";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
: Get the text from an TEI-XML document.
:
: @return the tei:text element as element(tei:text)?
:)
declare function pxml:get-text($xml as element(tei:TEI)) as element(tei:text)? {
    $xml/tei:text
};

(:~
: Get subsection from an TEI-XML document or snippet
:
: @return all tei:divs with tei:head as a direct child
: except tei:divs with tei:head as descendant of a tei:div
:)
declare function pxml:get-subsections($context as element()) as element(tei:div)* {
    $context//tei:div[tei:head] except $context//tei:div[tei:head]//tei:div
};
