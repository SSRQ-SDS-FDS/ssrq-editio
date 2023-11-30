xquery version "3.1";

module namespace tex="http://ssrq-sds-fds.ch/exist/apps/ssrq/processing/tex";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace pm-latex="http://www.tei-c.org/pm/models/ssrq/latex/module" at "../../transform/ssrq-latex-module.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
: Creates the TeX-Code from a TEI-XML-Document.
:
: @param $xml as element(tei:TEI) – The TEI-XML-Document to be transformed.
: @param $parameters as map(*)? – The parameters for the transformation.
: @return The TeX-Code as xs:string.
:)
declare function tex:create($xml as element(tei:TEI), $parameters as map(*)?) as xs:string {
    pm-latex:transform($xml, $parameters) => tex:postprocess()
};

(:~
: Postprocesses the TeX-Code.
:
: @param $tex as xs:string – The TeX-Code to be processed.
: @return The processed TeX-Code as xs:string.
:)
declare %private function tex:postprocess($tex as xs:string+) as xs:string {
    if (count($tex) = 1) then
        tex:replace-unwanted-space($tex)
    else
        tex:replace-unwanted-space(($tex, '&#xa;'))
};

(:~
: The Processing-Model generates a lot of unwanted spaces (linebreaks, tabs, etc.).
: This function removes them.
:
: @param $tex as xs:string – The TeX-Code to be processed.
: @return The processed TeX-Code as xs:string.
:)
declare %private function tex:replace-unwanted-space($tex as xs:string+) as xs:string {
    $tex => replace('(\s*\n){2,}', '&#xa;&#xa;') => replace('^[ \t]+', '', 'm')
};
