xquery version "3.1";

declare namespace alma="http://www.loc.gov/zing/srw/";
declare namespace diag="http://www.loc.gov/zing/srw/diagnostic/";
declare namespace marc="http://www.loc.gov/MARC21/slim";

import module namespace http="http://expath.org/ns/http-client" at "java:org.expath.exist.HttpClientModule";

(: let $id := request:get-parameter("id", "chbsg000140891") :)
let $id := request:get-parameter("id", "chbsg000125480")

let $api := "https://nb-bsg.userservices.exlibrisgroup.com/view/sru/41SNL_54_INST"
let $params := "version=1.2&amp;recordSchema=marcxml&amp;operation=searchRetrieve&amp;"
let $query := "query=alma.all_for_ui%3D" || $id
let $request := <http:request method="GET" href="{$api}?{$params}{$query}"/>
let $response := http:send-request($request)
let $result :=
    if ($response[1]/@status = "200") then
        if ($response[2]//alma:numberOfRecords/text() != "1") then
            <status bsg-id="{$id}">{$response[2]//alma:numberOfRecords}</status>
        else if ($response[2]//alma:diagnostics) then
            <status>{$response[2]//alma:diagnostics/diag:diagnostic}</status>
        else
            $response[2]
    else
        <status>{$response[1]}</status>

return
    if (not($result//marc:record)) then
        $result
    else
        let $is-book := exists($result//marc:record/marc:datafield[@tag="260"])
        let $is-edition := $result//marc:record/marc:datafield[@tag="996"]/marc:subfield[@code="b"] = "Edition"

        let $authors :=
            for $i in ($result//marc:record/marc:datafield[@tag="100" or @tag="700"]/marc:subfield[@code="a"])
                return <author>{$i/text()}</author>

        let $raw-title :=
            if (exists($result//marc:record/marc:datafield[@tag="245"]/marc:subfield[@code="b"])) then
                $result//marc:record/marc:datafield[@tag="245"]/marc:subfield[@code="a"]/text() || " " || $result//marc:record/marc:datafield[@tag="245"]/marc:subfield[@code="b"]/text()
            else
                $result//marc:record/marc:datafield[@tag="245"]/marc:subfield[@code="a"]/text()
        let $title := replace($raw-title, "(.+?)( /)?$", "$1")
        let $short-title := $result//marc:record/marc:datafield[@tag="524"]/marc:subfield[@code="a"]/text()

        let $publisher :=
            for $i in ($result//marc:record/marc:datafield[@tag="260"]/marc:subfield[@code="b"])
                return <publisher>{replace($i/text(), "(.+?) ?[:;,]$", "$1")}</publisher>
        let $pub-place :=
            for $i in ($result//marc:record/marc:datafield[@tag="260"]/marc:subfield[@code="a"])
                return <pubPlace>{replace($i/text(), "(.+?) ?[:;,]$", "$1")}</pubPlace>
        let $pub-date := $result//marc:record/marc:datafield[@tag="260"]/marc:subfield[@code="c"]/text()

        let $journal := $result//marc:record/marc:datafield[@tag="773"]/marc:subfield[@code="t"]/text()
        let $bibl-scope := $result//marc:record/marc:datafield[@tag="773"]/marc:subfield[@code="g"]/text()

        return
            <biblStruct xml:id="{$id}">
                {if ($is-book and $is-edition) then
                    <monogr type="edition">
                        {$authors}
                        <title>{$title}</title>
                        <title type="short">{$short-title}</title>
                        <imprint>
                            {for $i at $pos in ($publisher)
                                return ($i, $pub-place[$pos])
                            }
                            <date>{$pub-date}</date>
                        </imprint>
                    </monogr>
                 else if ($is-book) then
                    <monogr>
                        {$authors}
                        <title>{$title}</title>
                        <title type="short">{$short-title}</title>
                        <imprint>
                            {for $i at $pos in ($pub-place)
                                return ($i, $publisher[$pos])
                            }
                            <date>{$pub-date}</date>
                        </imprint>
                    </monogr>
                 else
                    (<analytic>
                        {$authors}
                        <title>{$title}</title>
                        <title type="short">{$short-title}</title>
                    </analytic>,
                    <monogr>
                        <title>{$journal}</title>
                        <biblScope>{$bibl-scope}</biblScope>
                    </monogr>)
                }
            </biblStruct>
