xquery version "3.1";

module namespace index="http://ssrq-sds-fds.ch/exist/apps/ssrq/index";

import module namespace ssrq-helper="http://ssrq-sds-fds.ch/exist/apps/ssrq/helper" at "ssrq-helper.xqm";
import module namespace app="http://ssrq-sds-fds.ch/exist/apps/ssrq/app" at "ssrq.xqm";
import module namespace i18n = 'http://exist-db.org/xquery/i18n' at "../lib/i18n.xqm";
import module namespace utils="http://ssrq-sds-fds.ch/exist/apps/ssrq/utils" at "utils.xqm";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";
import module namespace session="http://exist-db.org/xquery/session";
import module namespace ec="http://ssrq-sds-fds.ch/exist/apps/ssrq/odd/extension/common" at "ext-common.xqm";
import module namespace ssrq-lang="http://ssrq-sds-fds.ch/exist/apps/ssrq/lang" at "ssrq-lang.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function index:get-index-entries($id as xs:string) as element()* {
    let $xml := collection($config:data-root)//tei:TEI[.//tei:seriesStmt/tei:idno[normalize-space(text()) = $id]]
    return
        i18n:process(
                        <aside>{index:list-places($xml), index:list-persons($xml), index:list-organizations($xml), index:list-keys($xml), index:list-lemmata($xml)}</aside>,
                        $config:lang-settings?lang,
                        utils:path-concat(($config:app-root, 'resources/i18n')),
                        $ssrq-lang:fallback
                    )
};

declare function index:order-list-items($items as element(li)*) as element(li)* {
    for $item in $items
    order by $item/a collation "?lang=de_CH"
    return
        $item
};

declare function index:list-places($xml as node()) as element()* {
    let $places := $xml//(tei:placeName[@ref]|tei:origPlace[@ref])
    where exists($places)
    return
        (
            <h3 class="place">
                    <i18n:text key="places"/>
            </h3>,
            <ul class="register-list places">
                {
                    index:order-list-items(
                        for $place in app:api-lookup-xml($app:PLACES, app:api-keys($places/@ref), "id")//info
                        order by $place/stdName
                        return
                            <li data-ref="{$place/@id}">
                                <input type="checkbox" class="select-facet" title="i18n(highlight-facet)"></input>
                                <a target="_new" href="{ec:create-p-link-from-id($place/@id)}">{$place/stdName}</a>
                                ({$place/location})
                                {$place/type}
                            </li>
                    )
                }
            </ul>
        )
};



declare function index:list-keys($xml as node()) as element()* {
    let $keywords := $xml//tei:term[starts-with(@ref, 'key')]
    where exists($keywords)
    return
        (
            <h3 class="term">
                <i18n:text key="keywords"/>
            </h3>,
            <ul class="register-list keywords">
                {
                    index:order-list-items(
                        for $lemma in app:api-lookup-xml($app:KEYWORDS, app:api-keys($keywords/@ref), "id")//info
                        order by $lemma/name
                        return
                            <li data-ref="{$lemma/@id}">
                                <input type="checkbox" class="select-facet" title="i18n(highlight-facet)"/>
                                <a href="{ec:create-p-link-from-id($lemma/@id)}" target="_new">{$lemma/name}</a>
                            </li>
                    )
                }
            </ul>

        )
};


declare function index:list-lemmata($xml as node()) as element()* {
    let $lemmata := $xml//tei:term[starts-with(@ref, 'lem')]
    where exists($lemmata)
    return
        (
            <h3 class="term">
                <i18n:text key="lemma"/>
            </h3>,
             <ul class="register-list lemmata">
                {
                    index:order-list-items(
                        for $lemma in app:api-lookup-xml($app:LEMMA, app:api-keys($lemmata/@ref), "id")//info
                        order by $lemma/stdName
                        return
                            <li data-ref="{$lemma/@id}">
                                <input type="checkbox" class="select-facet" title="i18n(highlight-facet)"/>
                                <a target="_new" href="{ec:create-p-link-from-id($lemma/@id)}">{$lemma/stdName}</a>
                                ({$lemma/morphology})
                                {$lemma/definition}
                            </li>
                    )
                }
             </ul>
        )
};

declare function index:list-persons($xml as node()) as element()* {
    let $persons :=
        $xml//tei:persName/@ref |
        $xml//@scribe[starts-with(., 'per')]
    where exists($persons)
    return
        (
            <h3 class="person">
                <i18n:text key="person"/>
            </h3>,
            <ul class="register-list persons">
                {
                    index:order-list-items(
                        for $person in app:api-lookup($app:PERSONS, app:api-keys($persons), "ids_search")?*
                        order by $person?name
                        return
                            <li data-ref="{$person?id}">
                                <input type="checkbox" class="select-facet" title="i18n(highlight-facet)"/>
                                <a target="_new" href="{ec:create-p-link-from-id($person?id)}">{$person?name}</a>
                                    {
                                        if ($person?dates) then
                                            <span class="info"> ({$person?dates})</span>
                                        else
                                            ()
                                    }
                            </li>
                    )
                }
            </ul>
        )


};

declare function index:list-organizations($xml as node()) as element()* {
    let $organizations := $xml//tei:orgName/@ref
    where exists($organizations)
    return
        (
            <h3 class="organization">
                <i18n:text key="organisation"/>
            </h3>,
            <ul class="register-list organizations">
                {
                    index:order-list-items(
                        for $organization in app:api-lookup($app:PERSONS, app:api-keys($organizations), "ids_search")?*
                        order by $organization?name
                        return
                            <li data-ref="{$organization?id}">
                                <input type="checkbox" class="select-facet" title="i18n(highlight-facet)"/>
                                <a target="_new" href="{ec:create-p-link-from-id($organization?id)}">{$organization?name}</a>
                                    {
                                        if ($organization?type) then
                                            <span class="info"> ({$organization?type})</span>
                                        else
                                            ()
                                    }
                            </li>
                    )
                }
            </ul>
        )


};
