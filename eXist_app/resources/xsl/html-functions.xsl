<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:i18n="http://ssrq-sds-fds.ch/exist/apps/ssrq/i18n/module"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                xmlns:to-html="http://ssrq-sds-fds.ch/exist/apps/ssrq/rendering/to-html"
                exclude-result-prefixes="#all" expand-text="yes" version="3.0">
    
    <xsl:function name="to-html:heading" as="element()">
        <xsl:param name="level" as="xs:integer"/>
        <xsl:param name="content" as="item()*"/>
        <xsl:param name="class" as="xs:string*"/>
        <xsl:sequence>
            <xsl:element name="h{$level}">
                <xsl:sequence select="to-html:create-class-attribute($class)"/>
                <xsl:apply-templates select="$content"/>
            </xsl:element>
        </xsl:sequence>
    </xsl:function>
    
    <xsl:function name="to-html:inline" as="element()">
        <xsl:param name="name" as="xs:string"/>
        <xsl:param name="content" as="item()*"/>
        <xsl:param name="class" as="xs:string*"/>
        <xsl:sequence>
            <xsl:element name="{$name}">
                <xsl:sequence select="to-html:create-class-attribute($class)"/>
                <xsl:apply-templates select="$content"/>
            </xsl:element>
        </xsl:sequence>
    </xsl:function>
    
    <xsl:function name="to-html:create-class-attribute" as="attribute(class)?">
        <xsl:param name="class" as="xs:string*"/>
        <xsl:sequence>
            <xsl:if test="$class">
                <xsl:attribute name="class">
                    <xsl:value-of select="string-join($class, ' ')"/>
                </xsl:attribute>
            </xsl:if>
        </xsl:sequence>
    </xsl:function>
    
</xsl:stylesheet>
