xquery version "3.0";

module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config";

import module namespace pm-web="http://www.tei-c.org/pm/models/ssrq/web/module" at "../transform/ssrq-web-module.xql";
import module namespace pm-latex="http://www.tei-c.org/pm/models/ssrq/latex/module" at "../transform/ssrq-latex-module.xql";
import module namespace norm-web="http://www.tei-c.org/pm/models/ssrq-norm/web/module" at "../transform/ssrq-norm-web-module.xql";
import module namespace norm-latex="http://www.tei-c.org/pm/models/ssrq-norm/latex/module" at "../transform/ssrq-norm-latex-module.xql";

declare variable $pm-config:web-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    switch ($odd)
        case "ssrq-norm.odd" return
            norm-web:transform($xml, $parameters)
        default return
            pm-web:transform($xml, $parameters)
};

declare variable $pm-config:latex-transform := function($xml as node()*, $parameters as map(*)?, $odd as xs:string?) {
    pm-latex:transform($xml, $parameters)
    (: print-latex:transform($xml, $parameters) :)
};
