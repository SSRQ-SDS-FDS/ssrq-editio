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
    <xsl:param name="formatted-date" as="xs:string"/>
    <xsl:param name="has-facs" as="xs:string"/>
    <xsl:param name="lang" select="'de'" as="xs:string"/>
    <xsl:param name="link" as="xs:string"/>
    <xsl:param name="origPlace-ref" as="xs:string"/>
    <xsl:param name="printed-idno" as="xs:string"/>
    
    <xsl:template match="tei:TEI">
        <xsl:apply-templates select="tei:teiHeader"/>
    </xsl:template>
    
    <xsl:template match="tei:teiHeader">
        <a href="{$link}" class="document-info">
            <article>
                <header>
                    <xsl:sequence select="to-html:render-idno-icon($printed-idno)"/>
                    <xsl:sequence select="to-html:render-date-icon($formatted-date)"/>
                    <xsl:sequence select="to-html:render-place-icon($origPlace-ref)"/>
                    <xsl:sequence select="to-html:render-facs-icon(xs:boolean($has-facs))"/>
                </header>
                <xsl:apply-templates select="tei:fileDesc/tei:sourceDesc"/>
            </article>
        </a>
    </xsl:template>
    
    <xsl:template match="tei:sourceDesc">
        <xsl:apply-templates select="(.//tei:msDesc)[1]"/>
    </xsl:template>
    
    <xsl:template match="tei:msDesc">
        <xsl:apply-templates select="(tei:head[@xml:lang = $lang] | tei:head)[1]"/>
    </xsl:template>
    
    <xsl:template match="tei:head">
        <xsl:sequence select="to-html:heading(3, ./node() except ./tei:note, ())"/>
    </xsl:template>
    
    <!-- Fallback template for elements inside tei:head (except note, see above) -->
    <xsl:template match="tei:date|tei:persName|tei:placeName">
        <xsl:apply-templates select=".//text()"/>
    </xsl:template>
    
    <xsl:function name="to-html:render-idno-icon" as="element(span)">
        <xsl:param name="idno" as="xs:string"/>
        <xsl:sequence>
            <span>
                <svg
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 20
                         20"
                    fill="currentColor"
                    class="w-3.5 h-3.5 mr-0.5 md:mr-1"
                    >
                    <path
                        fill-rule="evenodd"
                        d="M4.5 2A1.5 1.5 0 003 3.5v13A1.5 1.5 0 004.5
                       18h11a1.5 1.5 0 001.5-1.5V7.621a1.5 1.5 0 00-.44-1.06l-4.12-4.122A1.5 1.5 0
                       0011.378 2H4.5zm2.25 8.5a.75.75 0 000 1.5h6.5a.75.75 0 000-1.5h-6.5zm0
                       3a.75.75 0 000 1.5h6.5a.75.75 0 000-1.5h-6.5z"
                        clip-rule="evenodd"
                        />
                </svg>
                <xsl:text expand-text="yes"> {$idno}</xsl:text>
            </span>
        </xsl:sequence>
    </xsl:function>
    
    <xsl:function name="to-html:render-date-icon" as="element(span)">
        <xsl:param name="date" as="xs:string"/>
        <xsl:sequence>
            <span>
                <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    class="w-3.5 h-3.5 mr-0.5 md:mr-1"
                    >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25
                       0 012.25-2.25h13.5A2.25 2.25 0 0121 7.5v11.25m-18 0A2.25 2.25 0
                       005.25 21h13.5A2.25 2.25 0 0021 18.75m-18 0v-7.5A2.25 2.25 0 015.25 9h13.5A2.25 2.25 0 0121 11.25v7.5"
                        />
                </svg>
                <xsl:text expand-text="yes"> {$date}</xsl:text>
            </span>
        </xsl:sequence>
    </xsl:function>
    
    <xsl:function name="to-html:render-place-icon" as="element(span)?">
        <xsl:param name="place" as="xs:string"/>
        <xsl:sequence>
            <xsl:if test="normalize-space($place) => string-length() > 0">
                <span>
                    <svg
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke-width="1.5"
                        stroke="currentColor"
                        class="w-3.5 h-3.5 mr-0.5 md:mr-1"
                        >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            d="M15 10.5a3 3 0 11-6 0 3 3 0 016 0z"
                            />
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1115 0z"
                            />
                    </svg>
                    <span data-place-ref="{$place}">
                        <span class="border-gray-300 h-3.5 w-3.5 animate-spin rounded-full border border-t-ssrq-primary"/>
                    </span>
                </span>
            </xsl:if>
        </xsl:sequence>
    </xsl:function>
    
    <xsl:function name="to-html:render-facs-icon" as="element(span)?">
        <xsl:param name="facs" as="xs:boolean"/>
        <xsl:sequence>
            <xsl:if test="$facs">
                <span>
                    <svg
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke-width="1.5"
                        stroke="currentColor"
                        class="w-3.5 h-3.5 mr-0.5 md:mr-1"
                        >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159
                           5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909m-18
                           3.75h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25
                           6v12a1.5 1.5 0 001.5 1.5zm10.5-11.25h.008v.008h-.008V8.25zm.375 0a.375.375
                           0 11-.75 0 .375.375 0 01.75 0z"
                            />
                    </svg>
                    <i18n:text key="has-facs">facs-info</i18n:text>
                </span>
            </xsl:if>
        </xsl:sequence>
    </xsl:function>
    
    
</xsl:stylesheet>
