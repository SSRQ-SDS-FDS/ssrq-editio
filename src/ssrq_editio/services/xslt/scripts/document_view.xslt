<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
                xmlns:cutils="http://ssrq-sds-fds.ch/xsl/tei2pub/functions/cutils"
                xmlns:date="http://ssrq-sds-fds.ch/xsl/tei2pub/functions/date"
                xmlns:i18n="http://ssrq-sds-fds.ch/xsl/tei2pub/functions/i18n"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                exclude-result-prefixes="#all" expand-text="yes" version="3.0">
    
    <xsl:output method="json" encoding="utf-8"/>
    
    <!-- Utility functions / modules -->
    <xsl:import href="./convert/src/ssrq_convert/tei2pub/xsl/functions/core-utils.xsl"/>
    <xsl:import href="./convert/src/ssrq_convert/tei2pub/xsl/functions/date.xsl"/>
    
    <!-- Templates for rendering -->
    <xsl:include href="./convert/src/ssrq_convert/tei2pub/xsl/html.xsl"/>
    
    
    
    <xsl:param name="lang" as="xs:string"/>
    <xsl:param name="translations" as="map(xs:string, map(*))"/>
    
    <xsl:template match="/">
        <xsl:variable name="type" as="xs:string" select=".//tei:text/@type"/>
        <xsl:map>
            <!-- ToDo: Implement conrect rendering here -->
            <xsl:map-entry key="'comment'" select="'Kommentar'"/>
            <xsl:map-entry key="'normalized_transcript'">
                <xsl:choose>
                    <xsl:when test="$type = 'transcript'">
                        <!-- ToDo: Implement conrect rendering here -->
                        <xsl:value-of select="'Normalisiertes Transkript'"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- A collection or summary never have a normalized transcript! -->
                        <xsl:value-of select="()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:map-entry>
            <!-- ToDo: Implement conrect rendering here -->
            <xsl:map-entry select="()" key="'summary'"/>
            <!-- ToDo: Implement conrect rendering here -->
            <xsl:map-entry key="'transcript'" select="'Quellennahes Transkript'"/>
            <xsl:map-entry key="'type'" select="$type"/>
        </xsl:map>
        
    </xsl:template>
    
</xsl:stylesheet>
