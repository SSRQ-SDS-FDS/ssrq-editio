xquery version "3.1";

module namespace about="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/about";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace find="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/finder" at "../repository/finder.xqm";
import module namespace i18n-settings="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/settings" at "../i18n/settings.xqm";
import module namespace xsl="http://ssrq-sds-fds.ch/exist/apps/ssrq/processing/xsl" at "../processing/xsl.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
: Render the list of partners
: using partners.xsl
:
: @param $node The node where the template is called from (passed by the templating engine)
: @param $model The model to use for the partners list (passed by the templating engine)
: @return The rendered list of partners as element(section)+ (passed to the templating engine)
:)
declare function about:list-partners($node as node(), $model as map(*)) as element(section)+ {
    let $lang := i18n-settings:get-lang-from-model-or-config($model)
    let $partners-xml := find:load-document-by-path(($config:misc-path, $config:partners))
    return
        xsl:apply(
            'partners.xsl',
            $partners-xml,
            map {
                'lang': $lang,
                'key-funding': 'funding',
                'key-partners': 'partners'
            }
    )
};
