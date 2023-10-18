xquery version "3.1";

module namespace idno-parser="http://ssrq-sds-fds.ch/exist/apps/ssrq/idno/parser";

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
    idno-parser:parse-regular($idno, idno-parser:handle-idno-groups#1)
};

(:~
: Parses an regular SSRQ idno and returns an structured
: XML element.
:
: @param $idno The idno to parse as xs:string
: @param $handler The handler function to call for each group as function(element(xpath:group)) as element()?
: @return The parsed idno as element (doc)
:)
declare function idno-parser:parse-regular($idno as xs:string, $handler as function(element(xpath:group)) as element()*) as element(doc) {
    <doc xml:id="{$idno}">
        {
            for $group in (analyze-string($idno, '^(SSRQ|SDS|FDS)
                                -([A-Z]{2})
                                -([A-Za-z0-9_]+)
                                -(?:((?:[A-Za-z0-9]+\.)*)([0-9]+)
                                -([0-9]+)|([a-z]{3,}))$', 'x'))//xpath:group
            return
                $handler($group)
        }
    </doc>
};

declare function idno-parser:handle-idno-groups($group as element(xpath:group)) as element()* {
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

declare function idno-parser:parse-case-part($group as element(xpath:group)) as element()* {
    for $i in tokenize($group/text(), '\.')
    return
        (
            <case>{$i}</case>[matches($i, '^\d+$')],
            <opening>{$i}</opening>[matches($i, '^[A-Za-z]+$')]
        )[1]
};
