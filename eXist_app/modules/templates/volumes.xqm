xquery version "3.1";

module namespace volumes="http://ssrq-sds-fds.ch/exist/apps/ssrq/templates/volumes";

import module namespace config="http://www.tei-c.org/tei-simple/config" at "../config.xqm";
import module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common" at "../ext-common.xqm";
import module namespace find="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/finder" at "../repository/finder.xqm";
import module namespace pm-config="http://www.tei-c.org/tei-simple/pm-config" at "../pm-config.xqm";
import module namespace ssrq-cache="http://ssrq-sds-fds.ch/exist/apps/ssrq/repository/cache" at "../repository/cache.xqm";
import module namespace ssrq-helper="http://ssrq-sds-fds.ch/exist/apps/ssrq/helper" at "../ssrq-helper.xqm";

declare namespace i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/module";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
: Templating function, which will list
: all volumes of per kanton
:
: @param $node node() - the current node (passed by the template engine)
: @param $model map(*) - the model (passed by the template engine)
: @param $kanton xs:string - the kanton (passed by the template engine / the request)
: @return element(div) - the rendered volumes
:)
declare function volumes:list($node as node(), $model as map(*), $kanton as xs:string) as element(div) {
    <div class="volumes">
        {
            for $volume in volumes:get-volumes($kanton)
            return
                volumes:render-volume-info($volume, $kanton)
        }
    </div>

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
: Render the volume info
:
: @param $volume element(volume) - the volume
: @param $kanton xs:string - the kanton
: @return element(div) - the rendered volume info
:)
declare %private function volumes:render-volume-info($volume as element(volume), $kanton as xs:string) as element(div) {
    <div class="volume">
        <div class="volume-counter">
            <span class="badge">
                {ssrq-helper:count-docs($volume)}
            </span>
            </div>
            {
                volumes:render-volume-title($volume),
                <a class="part" href="{ec:create-app-link(($kanton, $volume/@xml:id => substring(4), ''))}">
                    <i18n:text key="articles">Stücke</i18n:text>
                </a>,
                volumes:create-anchor-for-content-types($volume, $kanton)
            }
    </div>
};

(:~
: Render the volume title using the processing-model
:
: @param $volume element(volume) - the volume
: @return element(div) - the rendered volume title
:)
declare %private function volumes:render-volume-title($volume as element(volume)) as element(div) {
    let $example-document := find:article-by-idno($volume/doc[1]/@xml:id/data(.))
    return
        $pm-config:web-transform($example-document//tei:fileDesc, map { "root": $example-document, "view": "volumes" }, $config:odd)
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
        <a class="part" href="{volumes:link-to-paratext($content-type, $kanton, $volume)}">
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
