xquery version "3.1";

module namespace occurrences-list="http://ssrq-sds-fds.ch/exist/apps/ssrq/occurrences/list";

import module namespace find="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/finder" at "../repository/finder.xqm";
import module namespace occurrences-find="http://ssrq-sds-fds.ch/exist/apps/ssrq/occurrences/find" at "find.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
: Returns a list of all occurences in the corpus as a map.
: Uses find:regular-articles#0 as the default loader function.
:
: @return map(*) - A map of all occurences; splitted by entity-type.
:)
declare function occurrences-list:all() as map(*) {
    occurrences-list:all(find:regular-articles#0)
};

(:~
: Returns a list of all occurences in the corpus as a map.
:
: @param $loader-functions as (function() as element(tei:TEI)+)+ - A list of functions that return a list of articles.
: @return map(*) - A map of all occurences; splitted by entity-type.
:)
declare function occurrences-list:all($loader-functions as (function() as element(tei:TEI)+)+) as map(*) {
    let $docs := ($loader-functions ! .())
    return
        map {
            "keywords": occurrences-find:keywords($docs),
            "lemmata": occurrences-find:lemmata($docs),
            "persons": occurrences-find:persons($docs),
            "places": occurrences-find:places($docs)
        }
};
