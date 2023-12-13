xquery version "3.1";

module namespace head="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/head";

import module namespace templates = "http://exist-db.org/xquery/html-templating";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace i18n-settings="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/settings" at "../i18n/settings.xqm";
import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "../utils.xqm";

(: Will insert the page title into the template
: – should be used in the title-element as part of
: the head template. The title is generated
: per language and concatened with the 'subtitle' in the
: model.
:
: @param $node node() - the current node (passed by the template engine)
: @param $model map(*) - the model (passed by the template engine)
: @return node() - the rendered node with the title
:)
declare function head:page-title($node as node(), $model as map(*)) as element(title) {
    let $lang := i18n-settings:get-lang-from-model-or-config($model)
    let $subtitle := try { $model?configuration?param-resolver('subtitle') } catch * { () }
    return
        <title>
            {$config:app-titles($lang), if (exists($subtitle)) then (' · ', $subtitle) else ()}
        </title>
};

(: Templating function to create
: html meta tags for the page
:
: @param $node node() - the current node (passed by the template engine)
: @param $model map(*) - the model (passed by the template engine)
: @return element(meta)* - the rendered meta tags
:)
declare function head:meta($node as node(), $model as map(*)) as element(meta)* {
    <meta name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta name="creator" content="{$author/text()}"/>
};

(: Links to the css files
: created by the Processing Model
:
: @param $node node() - the current node (passed by the template engine)
: @param $model map(*) - the model (passed by the template engine)
: @return attribute(href) - the rendered link to the css file
:)
declare %templates:wrap function head:styles($node as node(), $model as map(*)) as attribute(href) {
    attribute href {
        let $name := replace($config:odd, "^([^/.]+).*$", "$1")
        return
            utils:path-concat(("{app}", $config:output, $name || ".css"))
    }
};
