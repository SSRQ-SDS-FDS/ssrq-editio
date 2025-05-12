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

    <xsl:param name="schema" as="element(tei:TEI)"/>

</xsl:stylesheet>
