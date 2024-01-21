<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/module"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                xmlns:to-html="http://ssrq-sds-fds.ch/exist/apps/ssrq/rendering/to-html"
                exclude-result-prefixes="#all" expand-text="yes" version="3.0">
    
    <xsl:import href="./common.xsl"/>
    
    <xsl:output method="html" indent="yes"/>
    <xsl:mode on-no-match="deep-skip"/>
    
    <!-- Used in templates defined in common.xsl -->
    <xsl:param name="mode" select="'web'"/>
    <xsl:param name="lang" select="'de'" as="xs:string"/>
    <xsl:param name="key-funding" as="xs:string"/>
    <xsl:param name="key-partners" as="xs:string"/>
    
    <xsl:variable name="role-keys" as="xs:string+" select="($key-funding, $key-partners)"/>
    
    <xsl:template match="tei:TEI">
        <xsl:apply-templates select="//tei:body"/>
    </xsl:template>
    
    <xsl:template match="tei:body">
        <xsl:apply-templates select="tei:dataSpec"/>
    </xsl:template>
    
    <xsl:template match="tei:dataSpec[@ident = $role-keys]">
        <xsl:sequence select="to-html:section(./@ident|tei:valList, ('centered-section', 'my-4'))"/>
    </xsl:template>
    
    <xsl:template match="@ident[parent::tei:dataSpec]">
        <xsl:variable name="content">
            <i18n:text key="{.}">{.}</i18n:text>
        </xsl:variable>
        <xsl:sequence select="to-html:heading(3, $content, 'title-3 my-1')"/>
    </xsl:template>
    
    
    <xsl:template match="tei:valList">
        <ul class="list-disc list-inside">
            <xsl:for-each select="./tei:valItem">
                <xsl:sort select="./tei:desc[@xml:lang = $lang]/tei:p => normalize-space()" lang="{$lang}"/>
                <xsl:variable name="desc" as="element(tei:desc)" select="./tei:desc[@xml:lang = $lang]"/>
                <li>
                    <xsl:choose>
                        <xsl:when test="$desc/tei:ref">
                            <xsl:sequence select="to-html:anchor($desc/tei:ref, $desc/tei:p, ('text-blue-600', 'hover:underline', 'cursor-pointer'))"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$desc/tei:p/string() => normalize-space()"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </li>
            </xsl:for-each>
        </ul>
    </xsl:template>
    
    <xsl:template match="tei:ref|tei:p">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="i18n:text">
        <xsl:copy-of select="."/>
    </xsl:template>
    
</xsl:stylesheet>
