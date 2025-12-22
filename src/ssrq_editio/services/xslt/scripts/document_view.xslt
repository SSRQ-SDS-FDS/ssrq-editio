<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
                xmlns:cutils="http://ssrq-sds-fds.ch/xsl/tei2pub/functions/cutils"
                xmlns:date="http://ssrq-sds-fds.ch/xsl/tei2pub/functions/date"
                xmlns:html="http://ssrq-sds-fds.ch/xsl/tei2pub/html"
                xmlns:i18n="http://ssrq-sds-fds.ch/xsl/tei2pub/functions/i18n"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                exclude-result-prefixes="#all" expand-text="yes" version="3.0">
    
    <xsl:output method="json" encoding="utf-8"/>
    
    <!-- Utility functions / modules -->
    <xsl:import href="./convert/src/ssrq_convert/tei2pub/xsl/functions/core-utils.xsl"/>
    <xsl:import href="./convert/src/ssrq_convert/tei2pub/xsl/functions/date.xsl"/>
    <xsl:import href="./convert/src/ssrq_convert/tei2pub/xsl/functions/text-utils.xsl"/>
    
    <!-- Templates for rendering -->
    <xsl:include href="./convert/src/ssrq_convert/tei2pub/xsl/html.xsl"/>
    
    
    
    <xsl:param name="create-normalized-transcript" as="xs:boolean" select="false()"/>
    <xsl:param name="lang" as="xs:string"/>
    <xsl:param name="translations" as="map(xs:string, map(*))"/>
    
    <xsl:template match="/">
        <xsl:variable name="type" as="xs:string" select=".//tei:text/@type"/>
        <xsl:choose>
            <xsl:when test="$create-normalized-transcript">
                <xsl:map>
                    <xsl:map-entry key="'normalized_transcript'">
                        <xsl:choose>
                            <xsl:when test="$type = 'transcript'">
                                <!-- ToDo: Implement correct rendering here -->
                                <xsl:value-of select="'Normalisiertes Transkript'"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- A collection or summary never have a normalized transcript! -->
                                <xsl:sequence select="()"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:map-entry>
                </xsl:map>
            </xsl:when>
            <xsl:otherwise>
                <xsl:map>
                    <xsl:map-entry key="'comment'">
                        <xsl:apply-templates select=".//tei:back">
                            <xsl:with-param name="lang" as="xs:string" tunnel="yes" select="$lang" />
                            <xsl:with-param name="translations" as="map(xs:string, map(*))" tunnel="yes" select="$translations"/>
                        </xsl:apply-templates>
                    </xsl:map-entry>
                    <xsl:variable name="descriptions" as="map(*)*">
                        <xsl:apply-templates select="cutils:get-document-manuscript-description(./tei:TEI) | cutils:get-secondary-document-manuscript-descriptions(./tei:TEI)">
                            <xsl:with-param name="lang" as="xs:string" tunnel="yes" select="$lang" />
                            <xsl:with-param name="translations" as="map(xs:string, map(*))" tunnel="yes" select="$translations"/>
                        </xsl:apply-templates>
                    </xsl:variable>
                    <xsl:map-entry key="'descriptions'" select="array{$descriptions}" />
                    <!-- ToDo: Implement correct rendering here -->
                    <xsl:map-entry key="'summary'">
                        <xsl:apply-templates select="(.//tei:summary[@xml:lang = $lang], .//tei:summary)[1]">
                            <xsl:with-param name="lang" as="xs:string" tunnel="yes" select="$lang" />
                            <xsl:with-param name="translations" as="map(xs:string, map(*))" tunnel="yes" select="$translations"/>
                        </xsl:apply-templates>
                    </xsl:map-entry>
                    <!-- ToDo: Implement conrect rendering here -->
                    <xsl:map-entry key="'transcript'">
                        <xsl:apply-templates select=".//tei:body" mode="html">
                            <xsl:with-param name="lang" as="xs:string" tunnel="yes" select="$lang" />
                            <xsl:with-param name="translations" as="map(xs:string, map(*))" tunnel="yes" select="$translations"/>
                        </xsl:apply-templates>
                    </xsl:map-entry>
                    <xsl:map-entry key="'type'" select="$type"/>
                </xsl:map>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tei:summary">
        <xsl:param name="lang" as="xs:string" tunnel="yes"/>
        <xsl:param name="translations" as="map(xs:string, map(*))" tunnel="yes"/>
        <xsl:map>
            <xsl:map-entry select="html:process-self(., $lang, $translations)" key="'content'"/>
            <xsl:map-entry select="./@xml:lang/data(.)" key="'lang'"/>
        </xsl:map>
    </xsl:template>
    
    <xsl:template match="tei:back">
        <xsl:param name="lang" as="xs:string" tunnel="yes"/>
        <xsl:param name="translations" as="map(xs:string, map(*))" tunnel="yes"/>
        <xsl:map>
            <xsl:map-entry select="html:process-self(., $lang, $translations)" key="'content'"/>
            <xsl:map-entry select="./@xml:lang/data(.)" key="'lang'"/> <!-- korrekt? -->
        </xsl:map>
    </xsl:template>
    
    <xsl:template match="tei:msDesc">
        <xsl:param name="lang" as="xs:string" tunnel="yes"/>
        <xsl:param name="translations" as="map(xs:string, map(*))" tunnel="yes"/>
        <xsl:variable name="use_lang" as="xs:string"
            select="(./tei:msIdentifier/*[@xml:lang = $lang]/@xml:lang[1], ./tei:msIdentifier/*/@xml:lang[1])[1]"/>
        <xsl:map>
            <xsl:map-entry key="'admin_info'">
                <xsl:sequence select="html:process-self(./tei:adminInfo, $lang, $translations)"/>
            </xsl:map-entry>
            <xsl:map-entry key="'archival_information'">
                <xsl:sequence select="html:process-self(./tei:msIdentifier, $lang, $translations)"/>
            </xsl:map-entry>
            <xsl:map-entry key="'bibliographic_information'">
                <xsl:sequence select="html:process-self(./tei:additional, $lang, $translations)"/>
            </xsl:map-entry>
            <xsl:map-entry key="'heading'">
                <xsl:map>
                    <xsl:map-entry key="'idno'">
                        <xsl:value-of select="./tei:msIdentifier/tei:idno[@xml:lang=$use_lang]" />
                    </xsl:map-entry>
                    <xsl:map-entry key="'lang'">
                        <xsl:value-of select="./tei:msContents/tei:msItem/tei:textLang/@xml:lang" />
                    </xsl:map-entry>
                    <xsl:map-entry key="'witnessNumber'">
                        <xsl:value-of select="./../@n" />
                    </xsl:map-entry>
                </xsl:map>
            </xsl:map-entry>
            <xsl:map-entry key="'ms_history'">
                <xsl:sequence select="html:process-self(./tei:history, $lang, $translations)"/>
            </xsl:map-entry>
            <xsl:map-entry key="'ms_information'">
                <xsl:sequence select="html:process-self(./tei:msContents/tei:msItem, $lang, $translations)"/>
            </xsl:map-entry>
            <xsl:map-entry key="'physical_description'">
                <xsl:sequence select="html:process-self(./tei:physDesc, $lang, $translations)"/>
            </xsl:map-entry>
        </xsl:map>
    </xsl:template>
    
</xsl:stylesheet>
