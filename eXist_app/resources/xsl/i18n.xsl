<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/module"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                exclude-result-prefixes="#all" expand-text="yes" version="3.0">
    
    <xsl:output method="html" indent="yes"/>
    <xsl:mode on-no-match="shallow-copy"/>
    
    <xsl:param name="lang-catalogue-path" as="xs:string"/>
    
    <xsl:variable name="lang-catalogue" select="doc($lang-catalogue-path)"/>
    
    <xsl:template match="i18n:text">
        <xsl:sequence select="i18n:translate(@key, .)"/>
    </xsl:template>
    
    <xsl:template match="@*[matches(., '^i18n\((.*)\)$')]">
        <xsl:variable name="key" as="xs:string" select="replace(., '^i18n\((.*)\)$', '$1')"/>
        <xsl:attribute name="{name()}" select="i18n:translate($key, $key)"/>
    </xsl:template>
    
    <xsl:function name="i18n:translate" as="item()+">
        <xsl:param name="key" as="xs:string"/>
        <xsl:param name="default" as="xs:string"/>
        <xsl:variable name="entry" as="element()?" select="$lang-catalogue//msg[@key = $key]"/>
        <xsl:sequence>
            <xsl:choose>
                <xsl:when test="exists($entry)">
                    <xsl:apply-templates select="$entry/node()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$default"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:sequence>
    </xsl:function>
    
    
</xsl:stylesheet>
