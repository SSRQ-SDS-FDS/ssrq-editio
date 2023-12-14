xquery version "3.1";

module namespace volumes="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/volumes";

import module namespace templates = "http://exist-db.org/xquery/html-templating";

import module namespace articles-list="http://ssrq-sds-fds.ch/exist/apps/ssrq/articles/list" at "../articles/list.xqm";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common" at "../ext-common.xqm";
import module namespace find="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/finder" at "../repository/finder.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xqm";
import module namespace ssrq-cache="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/cache" at "../repository/cache.xqm";
import module namespace ssrq-helper="http://ssrq-sds-fds.ch/exist/apps/ssrq/helper" at "../ssrq-helper.xqm";
import module namespace template-utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/utils" at "template-utils.xqm";
import module namespace xsl="http://ssrq-sds-fds.ch/exist/apps/ssrq/processing/xsl" at "../processing/xsl.xqm";

declare namespace i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/module";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
: Templating function, which will list
: all volumes per kanton and write them
: to the $model
:
: @param $node node() - the current node (passed by the template engine)
: @param $model map(*) - the model (passed by the template engine)
: @param $kanton xs:string - the kanton (passed by the template engine / the request)
: @return map(*) - a map, which will be merged with the model with the key "volumes"
:                  and array of the volume-element and a example-TEI-document for the volume as value
:)
declare %templates:wrap function volumes:list($node as node(), $model as map(*), $kanton as xs:string) as map(xs:string, item()+) {
    map {
        "volumes": volumes:get-volumes($kanton) ! [., find:article-by-idno(./doc[1]/@xml:id/data(.))]
    }
};

(: Creates a human readable id for the volume
: based on the info from the static docs list
:
: @param $node node() - the current node (passed by the template engine)
: @param $model map(*) - the model (passed by the template engine)
: @return node() - the node, which called the templating function, with the id as text
:)
declare function volumes:id($node as node(), $model as map(*)) as node() {
    let $doc as element(doc) := array:get($model?volume, 1)/doc[1]
    return
        element { node-name($node) } {
            $node/@* except $node/@data-template,
            string-join(($doc/prefix, $doc/kanton, $doc/volume), ' ')
        }
};

(:~
: Render a small badge with the number of articles
: in a volume
:
: @param $node node() - the current node (passed by the template engine)
: @param $model map(*) - the model (passed by the template engine)
: @return element(span) - the rendered badge
:)
declare function volumes:count($node as node(), $model as map(*)) as element(span) {
    template-utils:counter-badge(articles-list:count(array:get($model?volume, 1)))
};

(:~
: Get all volumes for a given kanton from the static docs list
:
:
: @param $kanton xs:string - the kanton
: @return element(volume)+ - the volumes
:)
declare %private function volumes:get-volumes($kanton as xs:string) as element(volume)+ {
    ssrq-cache:load-from-static-cache-by-id($config:static-cache-path, $config:static-docs-list, $kanton)/volume
};

(:~
: Render the volume title using the processing-model
:
: @param $volume element(volume) - the volume
: @return element(div) - the rendered volume title
:)
declare function volumes:render-volume-title($node as node(), $model as map(*)) as element(div) {
    xsl:apply('volume-title.xsl', array:get($model?volume, 2), ())
};

(:
: Templating function, which will render
: links to the different content types
: of a volume
:
: @param $node node() - the current node (passed by the template engine)
: @param $model map(*) - the model (passed by the template engine)
: @return element(a)+ - the links
:)
declare function volumes:render-links($node as node(), $model as map(*)) as element(a)+ {
    let $doc := array:get($model?volume, 1)/doc[1]
    let $kanton := $doc/kanton
    let $volume := $doc/volume
    return
        (
            <a class="part" href="{ec:create-app-link(($kanton, $volume))}">
                <i18n:text key="articles">Stücke</i18n:text>
            </a>,
            volumes:create-anchor-for-content-types(array:get($model?volume, 1), $kanton)
        )
};

(:~
: Create links for the different content types
:
: @param $volume element(volume) - the volume
: @param $kanton xs:string - the kanton
: @return element(a)+ - the links
:)
declare %private function volumes:create-anchor-for-content-types($volume as element(volume), $kanton as xs:string) as element(a)+ {
    for $content-type in (volumes:find-paratexts($volume), "pdf"[xs:boolean($volume/@pdf)])
    return
        <a class="part" href="{volumes:link-to-paratext($content-type, $kanton, volumes:get-volume-name($kanton, $volume))}">
            <i18n:text key="{$content-type}">{$content-type}</i18n:text>
        </a>
};

(:~
: Find the paratexts-types for a given volume
:
: @param $volume element(volume) - the volume (part of the static docs list)
: @return xs:string* - the paratexts-types
:)
declare %private function volumes:find-paratexts($volume as element(volume)) as  xs:string* {
    for $type in $config:paratext-types
    return
        $type[$volume/doc[./special = $type]]
};

(:~
: Get the name of a volume
: by it's @xml:id from the volume-element
: with the kanton stripped
:
: @param $kanton xs:string - the kanton
: @param $volume element(volume) - the volume
: @return xs:string - the name
:)
declare %private function volumes:get-volume-name($kanton as xs:string, $volume as element(volume)) as xs:string {
    substring-after($volume/@xml:id, $kanton || '-')
};

(:~
: Create a link to a editorial paratext
: based on it's type
:
: @param $type xs:string - the type of the paratext
: @param $kanton xs:string - the kanton
: @param $volume xs:string - the volume
: @return xs:string - the link
:)
declare %private function volumes:link-to-paratext($type as xs:string, $kanton as xs:string, $volume as xs:string) as xs:string {
    switch ($type)
        case 'pdf' return
            ec:create-app-link(($kanton, $volume || '.pdf'))
        default return
            ec:create-app-link(($kanton, $volume, $type || '.html'))
};
