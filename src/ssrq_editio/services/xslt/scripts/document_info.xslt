<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
                xmlns:cutils="http://ssrq-sds-fds.ch/xsl/tei2pub/functions/cutils"
                xmlns:date="http://ssrq-sds-fds.ch/xsl/tei2pub/functions/date"
                xmlns:i18n="http://ssrq-sds-fds.ch/xsl/tei2pub/functions/i18n"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                exclude-result-prefixes="#all" expand-text="yes" version="3.0">

    <xsl:import href="./convert/src/ssrq_convert/tei2pub/xsl/functions/core-utils.xsl"/>
    <xsl:import href="./convert/src/ssrq_convert/tei2pub/xsl/functions/date.xsl"/>

    <xsl:import href="./convert/src/ssrq_convert/tei2pub/xsl/html.xsl"/>

    <xsl:param name="schema" as="xs:string"/>

    <xsl:output method="json" encoding="utf-8"/>

    <xsl:template match="/">
        <xsl:variable name="idno" as="text()" select="cutils:get-document-idno(./tei:TEI)/text()"/>
        <xsl:map>
            <xsl:map-entry key="'uuid'" select="cutils:get-document-uuid(./tei:TEI)/text()"/>
            <xsl:map-entry key="'idno'" select="$idno"/>
            <xsl:map-entry key="'printed_idno'" select="cutils:print-idno($idno)"/>
            <xsl:map-entry key="'facs'" select=".//tei:pb/@facs/data() => cutils:seq-to-array()"/>
            <xsl:map-entry key="'entities'" select="cutils:list-entity-references(./tei:TEI) => cutils:seq-to-array()"/>
            <xsl:apply-templates select="(.//tei:msDesc)[1]">
                <xsl:with-param
                    name="translations"
                    as="map(xs:string, map(*))"
                    tunnel="yes"
                    select="i18n:create-translation-map(doc($schema)/tei:TEI)"
                    />
            </xsl:apply-templates>
            <xsl:map-entry key="'type'" select=".//tei:text/@type/data(.)"/>
        </xsl:map>
    </xsl:template>

    <xsl:template match="tei:msDesc">
        <xsl:apply-templates select="./tei:history/tei:origin|tei:head"/>
    </xsl:template>

    <xsl:template match="tei:head">
        <xsl:param name="translations" as="map(xs:string, map(*))" tunnel="yes"/>
        <xsl:variable name="head">
            <xsl:apply-templates select="." mode="html">
                <xsl:with-param name="lang" as="xs:string" select="'de'" tunnel="yes"/>
                <xsl:with-param name="translations" as="map(xs:string, map(*))" select="$translations"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:map-entry
            key="(./@xml:lang, ./ancestor::tei:TEI/@xml:lang)[1] || '_title'"
            select="$head => serialize() => normalize-space()"
            />
    </xsl:template>

    <xsl:template match="tei:origin">
        <xsl:if test=".[tei:origPlace]">
            <xsl:variable name="references" as="xs:string+">
                <xsl:choose>
                    <xsl:when test=".[tei:origPlace[@type='document']][tei:origPlace[@type='content']]">
                        <xsl:sequence select="./tei:origPlace[@type='content']/@ref ! cutils:extract-main-entity-id(.)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="./tei:origPlace/@ref ! cutils:extract-main-entity-id(.)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:map-entry key="'orig_place'">
                <xsl:sequence select="cutils:seq-to-array($references)"/>
            </xsl:map-entry>
        </xsl:if>
        <xsl:apply-templates select="(tei:origDate[@type = 'content'], tei:origDate[@type = 'document'])[1]"/>
    </xsl:template>

    <xsl:template match="tei:origDate">
        <xsl:param name="translations" as="map(xs:string, map(*))" tunnel="yes"/>
        <xsl:call-template name="render-origDate">
            <xsl:with-param name="translations" select="$translations" tunnel="yes"/>
        </xsl:call-template>
        <xsl:call-template name="extract-orig-years"/>
    </xsl:template>

    <xsl:template name="render-origDate">
        <xsl:param name="translations" as="map(xs:string, map(*))" tunnel="yes"/>
        <xsl:variable name="context" as="element(tei:origDate)" select="."/>
        <xsl:for-each select="$supported-languages">
            <xsl:variable name="rendered-date">
                <xsl:apply-templates select="$context" mode="html">
                    <xsl:with-param name="lang" as="xs:string" select="." tunnel="yes"/>
                    <xsl:with-param name="translations" as="map(xs:string, map(*))" select="$translations"/>
                </xsl:apply-templates>
            </xsl:variable>
            <xsl:map-entry key=". || '_orig_date'" select="$rendered-date => serialize() => normalize-space()"/>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="extract-orig-years">
        <xsl:choose>
            <xsl:when test=".[@when-custom] and date:is-full-date(@when-custom)">
                <xsl:call-template name="extract-orig-years-when-custom">
                    <xsl:with-param name="date" select="./@when-custom"/>
                    <xsl:with-param name="calendar" select="./@calendar"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:when test="(.[@from-custom] and .[@to-custom]) or (.[@notBefore-custom] and .[@notAfter-custom])">
                <xsl:call-template name="extract-orig-years-from-to">
                    <xsl:with-param name="start" select="(./@from-custom, ./@notBefore-custom)[1]"/>
                    <xsl:with-param name="end" select="(./@to-custom, ./@notAfter-custom)[1]"/>
                    <xsl:with-param name="calendar" select="./@calendar"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:map-entry key="'start_year_of_creation'" select="()"/>
                <xsl:map-entry key="'end_year_of_creation'" select="()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="extract-orig-years-when-custom">
        <xsl:param name="date" as="xs:string"/>
        <xsl:param name="calendar" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="date:is-old-calendar($calendar)">
                <xsl:variable name="gregorian-date" select="date:convert-julian-date-to-gregorian-date($date)"/>
                <xsl:map-entry key="'start_year_of_creation'" select="$gregorian-date => date:extract-year()"/>
                <xsl:map-entry key="'end_year_of_creation'" select="()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:map-entry key="'start_year_of_creation'" select="date:extract-year($date)"/>
                <xsl:map-entry key="'end_year_of_creation'" select="()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="extract-orig-years-from-to">
        <xsl:param name="start" as="xs:string"/>
        <xsl:param name="end" as="xs:string"/>
        <xsl:param name="calendar" as="xs:string?"/>

        <xsl:variable name="start-is-full-date" select="date:is-full-date($start)"/>
        <xsl:variable name="end-is-full-date" select="date:is-full-date($end)"/>

        <xsl:choose>
            <xsl:when test="$start-is-full-date and $end-is-full-date and date:is-old-calendar($calendar)">
                <xsl:map-entry
                    key="'start_year_of_creation'"
                    select="date:convert-julian-date-to-gregorian-date($start) => date:extract-year()"
                    />
                <xsl:map-entry
                    key="'end_year_of_creation'"
                    select="date:convert-julian-date-to-gregorian-date($end) => date:extract-year()"
                    />
            </xsl:when>
            <xsl:when test="$start-is-full-date and $end-is-full-date">
                <xsl:map-entry key="'start_year_of_creation'" select="date:extract-year($start)"/>
                <xsl:map-entry key="'end_year_of_creation'" select="date:extract-year($end)"/>
            </xsl:when>
            <xsl:when test="date:is-old-calendar($calendar) and $start-is-full-date and not($end-is-full-date)">
                <xsl:map-entry
                    key="'start_year_of_creation'"
                    select="date:convert-julian-date-to-gregorian-date($start) => date:extract-year()"
                    />
                <xsl:map-entry key="'end_year_of_creation'" select="()"/>
            </xsl:when>
            <xsl:when test="date:is-old-calendar($calendar) and not($start-is-full-date) and $end-is-full-date">
                <xsl:map-entry key="'start_year_of_creation'" select="()"/>
                <xsl:map-entry
                    key="'end_year_of_creation'"
                    select="date:convert-julian-date-to-gregorian-date($end) => date:extract-year()"
                    />
            </xsl:when>
            <xsl:when test="$start-is-full-date and not($end-is-full-date)">
                <xsl:map-entry key="'start_year_of_creation'" select="date:extract-year($start)"/>
                <xsl:map-entry key="'end_year_of_creation'" select="()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:map-entry key="'start_year_of_creation'" select="()"/>
                <xsl:map-entry key="'end_year_of_creation'" select="date:extract-year($end)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>




</xsl:stylesheet>
