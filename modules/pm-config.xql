xquery version "3.0";

module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config";

import module namespace pm-web="http://www.tei-c.org/pm/models/ssrq/web/module" at "../transform/ssrq-web-module.xql";
import module namespace pm-print="http://www.tei-c.org/pm/models/ssrq/fo/module" at "../transform/ssrq-print-module.xql";
import module namespace pm-latex="http://www.tei-c.org/pm/models/ssrq/latex/module" at "../transform/ssrq-latex-module.xql";
import module namespace pm-epub="http://www.tei-c.org/pm/models/ssrq/epub/module" at "../transform/ssrq-epub-module.xql";
import module namespace norm-web="http://www.tei-c.org/pm/models/ssrq-norm/web/module" at "../transform/ssrq-norm-web-module.xql";
import module namespace norm-print="http://www.tei-c.org/pm/models/ssrq-norm/fo/module" at "../transform/ssrq-norm-print-module.xql";
import module namespace norm-latex="http://www.tei-c.org/pm/models/ssrq-norm/latex/module" at "../transform/ssrq-norm-latex-module.xql";
import module namespace norm-epub="http://www.tei-c.org/pm/models/ssrq-norm/epub/module" at "../transform/ssrq-norm-epub-module.xql";

declare variable $pm-config:web-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
        case "ssrq-norm.odd" return
            norm-web:transform($xml, $parameters)
        default return
            pm-web:transform($xml, $parameters)
};

declare variable $pm-config:print-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
        case "ssrq-norm.odd" return
            norm-print:transform($xml, $parameters)
        default return
            pm-print:transform($xml, $parameters)
};

declare variable $pm-config:latex-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    pm-latex:transform($xml, $parameters)
    (: print-latex:transform($xml, $parameters) :)
};

declare variable $pm-config:epub-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
        case "ssrq-norm.odd" return
            norm-epub:transform($xml, $parameters)
        default return
            pm-epub:transform($xml, $parameters)
};
