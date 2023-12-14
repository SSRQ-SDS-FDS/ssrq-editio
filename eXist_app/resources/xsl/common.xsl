<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/module"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                xmlns:to-html="http://ssrq-sds-fds.ch/exist/apps/ssrq/rendering/to-html"
                exclude-result-prefixes="#all" expand-text="yes" version="3.0">
    
    <xsl:import href="./html-functions.xsl"/>
    
    <xsl:param name="mode" as="xs:string" select="'web'"/>
    
    <xsl:template match="tei:hi[@rend = 'sup'][$mode = 'web']">
        <xsl:sequence select="to-html:inline(@rend, ./node(), ())"/>
    </xsl:template>
    
    <xsl:template match="text()">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>
    
</xsl:stylesheet>
