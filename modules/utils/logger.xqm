xquery version "3.1";

module namespace logger="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils/logger";

import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";

(:~
: Log a message, but don't raise an error
:
: @param $message The message to log
:)
declare function logger:log-and-raise-error($message as xs:string) as empty-sequence() {
    logger:log-and-raise-error($message, false())
};

(:~
: Log a message and raise an error
:
: @param $message The message to log
: @param $raise Whether to raise an error
:)
declare function logger:log-and-raise-error($message as xs:string, $raise as xs:boolean) as empty-sequence() {
    console:log($message), error((), $message)
};
