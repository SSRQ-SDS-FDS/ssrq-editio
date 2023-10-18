xquery version "3.1";

module namespace find="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/finder";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function find:regular-articles() as element(tei:TEI)+ {
    collection($config:data-root)/tei:TEI[not(@type)][.//tei:seriesStmt/tei:idno[not(@type = 'uuid')]]
};

declare function find:paratextual-documents() as element(tei:TEI)+ {
    collection($config:data-root)//tei:TEI[@type][.//tei:seriesStmt/tei:idno[not(@type = 'uuid')]]
};
