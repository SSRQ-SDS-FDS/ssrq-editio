module namespace error="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/error";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";

(:
: Display an error message
: if the environment is set to 'dev', the error message will be displayed
: otherwise, the error message will be empty
:
: @param $node the node that caused the error
: @param $model the model of the node that caused the error
: @return the error message or nothing
:)
declare function error:display($node as node(), $model as map(*)) as node()? {
    if ($config:env/env = 'dev') then
    element { node-name($node) } {
        $node/@* except $node/@data-template,
        $model?description
    }
    else
        ()
};
