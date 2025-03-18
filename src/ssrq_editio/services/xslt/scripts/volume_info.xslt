<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                exclude-result-prefixes="#all" expand-text="yes" version="3.0">
    
    <xsl:import href="./convert/src/ssrq_convert/tei2pub/xsl/functions/core-utils.xsl"/>
    <xsl:import href="./convert/src/ssrq_convert/tei2pub/xsl/functions/date.xsl"/>
    
    <xsl:import href="./convert/src/ssrq_convert/tei2pub/xsl/html.xsl"/>
    
    <xsl:output method="json" encoding="utf-8"/>
    
    <xsl:template match="/">
        <xsl:variable name="editors" as="text()+">
            <xsl:apply-templates select=".//tei:teiHeader//tei:editor"/>
        </xsl:variable>
        <xsl:map>
            <xsl:map-entry key="'title'">
                <xsl:variable name="result" as="element(h3)" >
                    <xsl:apply-templates select=".//tei:titleStmt/tei:title"/>
                </xsl:variable>
                <xsl:sequence select="$result => serialize() => normalize-space()"/>
            </xsl:map-entry>
            <xsl:map-entry key="'editors'" select="array{$editors}"/>
        </xsl:map>
    </xsl:template>
    
    <xsl:template match="tei:editor">
        <xsl:value-of select="./string() => normalize-space()"/>
    </xsl:template>
    
    <xsl:template match="tei:title">
        <h3>
            <xsl:apply-templates mode="html">
                <!-- Parameter need to be applied as default, but they will never be used in this context -->
                <xsl:with-param name="lang" as="xs:string" select="'de'" tunnel="yes"/>
                <xsl:with-param name="translations" as="map(xs:string, map(*))" select="map{}" tunnel="yes"/>
            </xsl:apply-templates>
        </h3>
    </xsl:template>
    
</xsl:stylesheet>
