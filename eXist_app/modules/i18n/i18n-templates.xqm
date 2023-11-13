module namespace intl="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/templates";

(:~
 : i18n template functions. Integrates the i18n library module. Called from the templating framework.
 :)
import module namespace i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/module" at "i18n.xqm";
import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "../utils.xqm";

(:~
 : Template function: calls i18n:process on the child nodes of $node.
 : Template parameters:
 :      lang=de Language selection
 :      catalogues=relative path    Path to the i18n catalogue XML files inside database
 :)
declare function intl:translate($node as node(), $model as map(*), $lang as xs:string?) {
    let $lang := $config:lang-settings?lang
    let $processed := templates:process($node/*, $model)
    let $translated :=
        i18n:process($processed, $lang, ())
    return
        element { node-name($node) } {
            $node/@*,
            $translated
        }
};
