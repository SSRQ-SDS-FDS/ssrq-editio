<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/module"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                xmlns:to-html="http://ssrq-sds-fds.ch/exist/apps/ssrq/rendering/to-html"
                exclude-result-prefixes="#all" expand-text="yes" version="3.0">
    
    <xsl:import href="./common.xsl"/>
    <xsl:import href="./html-functions.xsl"/>
    
    <xsl:output method="html" indent="yes"/>
    <xsl:mode on-no-match="deep-skip"/>
    
    <!-- Used in templates defined in common.xsl -->
    <xsl:param name="mode" select="'web'"/>
    
    <xsl:template match="tei:TEI">
        <xsl:apply-templates select="tei:teiHeader"/>
    </xsl:template>
    
    <xsl:template match="tei:teiHeader">
        <div class="volume-title">
            <xsl:apply-templates select="tei:fileDesc/tei:titleStmt"/>
        </div>
    </xsl:template>
    
    <xsl:template match="tei:titleStmt">
        <xsl:apply-templates select="tei:title"/>
        <p>
            <i18n:text key="by">von</i18n:text>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="tei:editor"/>
        </p>
    </xsl:template>
    
    <xsl:template match="tei:title">
        <xsl:sequence select="to-html:heading(3, ./node(), ())"/>
    </xsl:template>
    
    <xsl:template match="tei:editor[count(following-sibling::tei:editor) > 1]">
        <xsl:apply-templates/>
        <xsl:text>, </xsl:text>
    </xsl:template>
    
    <xsl:template match="tei:editor[count(following-sibling::tei:editor) = 1]">
        <xsl:apply-templates/>
        <xsl:text> </xsl:text>
        <i18n:text key="and">und</i18n:text>
        <xsl:text> </xsl:text>
    </xsl:template>
    
    <xsl:template match="tei:editor[not(following-sibling::tei:editor)]">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="tei:persName">
        <span class="editor">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
</xsl:stylesheet>
