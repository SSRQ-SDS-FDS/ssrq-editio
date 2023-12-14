xquery version "3.1";

module namespace index="http://ssrq-sds-fds.ch/exist/apps/ssrq/query/index";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace ssrq-cache="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/cache" at "cache.xqm";
import module namespace console="http://exist-db.org/xquery/console";

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
declare function index:get-title($doc as element(tei:TEI)) as xs:string? {
    ($doc//tei:msDesc/tei:head)[1]//text()[not(parent::tei:note)]
    => string-join(' ')
    => replace('\s+', ' ')
};
