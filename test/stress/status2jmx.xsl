<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:jmx="http://exist-db.org/jmx"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">

    <xsl:param name="path">/exist/apps/ssrq</xsl:param>
    <xsl:param name="host">${__property(http.server,,localhost)}</xsl:param>
    <xsl:param name="port">${__property(http.port,,8080)}</xsl:param>
    <xsl:param name="root">${__property(http.path,,<xsl:value-of select="$path"/>)}</xsl:param>
    <xsl:param name="threads">${__property(threads,,20)}</xsl:param>
    <xsl:param name="loops">${__property(loops,,1)}</xsl:param>
    
    <xsl:param name="duplicates" select="false()"/>
    
    <xsl:template match="/">
        <jmeterTestPlan version="1.2" properties="2.8" jmeter="2.13 r1665067">
            <hashTree>
                <TestPlan guiclass="TestPlanGui" testclass="TestPlan" testname="Testplan"
                    enabled="true">
                    <stringProp name="TestPlan.comments"/>
                    <boolProp name="TestPlan.functional_mode">false</boolProp>
                    <boolProp name="TestPlan.serialize_threadgroups">false</boolProp>
                    <elementProp name="TestPlan.user_defined_variables" elementType="Arguments"
                        guiclass="ArgumentsPanel" testclass="Arguments"
                        testname="Benutzer definierte Variablen" enabled="true">
                        <collectionProp name="Arguments.arguments">
                            <elementProp name="host" elementType="Argument">
                                <stringProp name="Argument.name">host</stringProp>
                                <stringProp name="Argument.value"><xsl:value-of select="$host"/></stringProp>
                                <stringProp name="Argument.metadata">=</stringProp>
                            </elementProp>
                            <elementProp name="port" elementType="Argument">
                                <stringProp name="Argument.name">port</stringProp>
                                <stringProp name="Argument.value"><xsl:value-of select="$port"/></stringProp>
                                <stringProp name="Argument.metadata">=</stringProp>
                            </elementProp>
                            <elementProp name="root" elementType="Argument">
                                <stringProp name="Argument.name">root</stringProp>
                                <stringProp name="Argument.value"><xsl:value-of select="$root"/></stringProp>
                                <stringProp name="Argument.metadata">=</stringProp>
                            </elementProp>
                        </collectionProp>
                    </elementProp>
                    <stringProp name="TestPlan.user_define_classpath"/>
                </TestPlan>
                <hashTree>
                    <ThreadGroup guiclass="ThreadGroupGui" testclass="ThreadGroup"
                        testname="{replace(document-uri(root(.)), '^.*?([^/]+)$', '$1')}"
                        enabled="true">
                        <stringProp name="ThreadGroup.on_sample_error">continue</stringProp>
                        <elementProp name="ThreadGroup.main_controller" elementType="LoopController"
                            guiclass="LoopControlPanel" testclass="LoopController"
                            testname="Loop Controller" enabled="true">
                            <boolProp name="LoopController.continue_forever">false</boolProp>
                            <stringProp name="LoopController.loops"><xsl:value-of select="$loops"/></stringProp>
                        </elementProp>
                        <stringProp name="ThreadGroup.num_threads">
                            <xsl:value-of select="$threads"/>
                        </stringProp>
                        <stringProp name="ThreadGroup.ramp_time">3</stringProp>
                        <longProp name="ThreadGroup.start_time">1282596044000</longProp>
                        <longProp name="ThreadGroup.end_time">1282596044000</longProp>
                        <boolProp name="ThreadGroup.scheduler">false</boolProp>
                        <stringProp name="ThreadGroup.duration"/>
                        <stringProp name="ThreadGroup.delay"/>
                    </ThreadGroup>
                    <hashTree>
                        <RandomOrderController guiclass="RandomOrderControllerGui"
                            testclass="RandomOrderController"
                            testname="Zufalls-Reihenfolgen-Controller" enabled="true"/>
                        <hashTree>
                            <xsl:apply-templates select=".//jmx:RecentQueryHistory"/>
                        </hashTree>
                        <ResultCollector guiclass="SummaryReport" testclass="ResultCollector"
                            testname="Summary Report" enabled="true">
                            <boolProp name="ResultCollector.error_logging">false</boolProp>
                            <objProp>
                                <name>saveConfig</name>
                                <value class="SampleSaveConfiguration">
                                    <time>true</time>
                                    <latency>true</latency>
                                    <timestamp>true</timestamp>
                                    <success>true</success>
                                    <label>true</label>
                                    <code>true</code>
                                    <message>true</message>
                                    <threadName>true</threadName>
                                    <dataType>true</dataType>
                                    <encoding>false</encoding>
                                    <assertions>true</assertions>
                                    <subresults>true</subresults>
                                    <responseData>false</responseData>
                                    <samplerData>false</samplerData>
                                    <xml>true</xml>
                                    <fieldNames>false</fieldNames>
                                    <responseHeaders>false</responseHeaders>
                                    <requestHeaders>false</requestHeaders>
                                    <responseDataOnError>false</responseDataOnError>
                                    <saveAssertionResultsFailureMessage>false</saveAssertionResultsFailureMessage>
                                    <assertionsResultsToSave>0</assertionsResultsToSave>
                                    <bytes>true</bytes>
                                    <threadCounts>true</threadCounts>
                                </value>
                            </objProp>
                            <stringProp name="filename"/>
                        </ResultCollector>
                        <hashTree/>
                        <ResultCollector guiclass="ViewResultsFullVisualizer"
                            testclass="ResultCollector" testname="View Results Tree" enabled="true">
                            <boolProp name="ResultCollector.error_logging">false</boolProp>
                            <objProp>
                                <name>saveConfig</name>
                                <value class="SampleSaveConfiguration">
                                    <time>true</time>
                                    <latency>true</latency>
                                    <timestamp>true</timestamp>
                                    <success>true</success>
                                    <label>true</label>
                                    <code>true</code>
                                    <message>true</message>
                                    <threadName>true</threadName>
                                    <dataType>true</dataType>
                                    <encoding>false</encoding>
                                    <assertions>true</assertions>
                                    <subresults>true</subresults>
                                    <responseData>false</responseData>
                                    <samplerData>false</samplerData>
                                    <xml>true</xml>
                                    <fieldNames>false</fieldNames>
                                    <responseHeaders>false</responseHeaders>
                                    <requestHeaders>false</requestHeaders>
                                    <responseDataOnError>false</responseDataOnError>
                                    <saveAssertionResultsFailureMessage>false</saveAssertionResultsFailureMessage>
                                    <assertionsResultsToSave>0</assertionsResultsToSave>
                                    <bytes>true</bytes>
                                    <threadCounts>true</threadCounts>
                                </value>
                            </objProp>
                            <stringProp name="filename"/>
                        </ResultCollector>
                        <hashTree/>
                        <ResultCollector guiclass="RespTimeGraphVisualizer"
                            testclass="ResultCollector" testname="Response Time Graph"
                            enabled="true">
                            <boolProp name="ResultCollector.error_logging">false</boolProp>
                            <objProp>
                                <name>saveConfig</name>
                                <value class="SampleSaveConfiguration">
                                    <time>true</time>
                                    <latency>true</latency>
                                    <timestamp>true</timestamp>
                                    <success>true</success>
                                    <label>true</label>
                                    <code>true</code>
                                    <message>true</message>
                                    <threadName>true</threadName>
                                    <dataType>true</dataType>
                                    <encoding>false</encoding>
                                    <assertions>true</assertions>
                                    <subresults>true</subresults>
                                    <responseData>false</responseData>
                                    <samplerData>false</samplerData>
                                    <xml>false</xml>
                                    <fieldNames>false</fieldNames>
                                    <responseHeaders>false</responseHeaders>
                                    <requestHeaders>false</requestHeaders>
                                    <responseDataOnError>false</responseDataOnError>
                                    <saveAssertionResultsFailureMessage>false</saveAssertionResultsFailureMessage>
                                    <assertionsResultsToSave>0</assertionsResultsToSave>
                                    <bytes>true</bytes>
                                    <threadCounts>true</threadCounts>
                                </value>
                            </objProp>
                            <stringProp name="filename"
                                >history-state-gov-reposonse-time-graph</stringProp>
                        </ResultCollector>
                        <hashTree/>
                        <ResultCollector guiclass="StatGraphVisualizer" testclass="ResultCollector"
                            testname="Aggregate Graph" enabled="true">
                            <boolProp name="ResultCollector.error_logging">false</boolProp>
                            <objProp>
                                <name>saveConfig</name>
                                <value class="SampleSaveConfiguration">
                                    <time>true</time>
                                    <latency>true</latency>
                                    <timestamp>true</timestamp>
                                    <success>true</success>
                                    <label>true</label>
                                    <code>true</code>
                                    <message>true</message>
                                    <threadName>true</threadName>
                                    <dataType>true</dataType>
                                    <encoding>false</encoding>
                                    <assertions>true</assertions>
                                    <subresults>true</subresults>
                                    <responseData>false</responseData>
                                    <samplerData>false</samplerData>
                                    <xml>false</xml>
                                    <fieldNames>false</fieldNames>
                                    <responseHeaders>false</responseHeaders>
                                    <requestHeaders>false</requestHeaders>
                                    <responseDataOnError>false</responseDataOnError>
                                    <saveAssertionResultsFailureMessage>false</saveAssertionResultsFailureMessage>
                                    <assertionsResultsToSave>0</assertionsResultsToSave>
                                    <bytes>true</bytes>
                                    <threadCounts>true</threadCounts>
                                </value>
                            </objProp>
                            <stringProp name="filename"/>
                        </ResultCollector>
                        <hashTree/>
                        <GaussianRandomTimer guiclass="GaussianRandomTimerGui"
                            testclass="GaussianRandomTimer"
                            testname="Gauss&apos;scher Zufalls-Zeitgeber" enabled="true">
                            <stringProp name="ConstantTimer.delay">100</stringProp>
                            <stringProp name="RandomTimer.range">2000.0</stringProp>
                        </GaussianRandomTimer>
                        <hashTree/>
                    </hashTree>
                </hashTree>
            </hashTree>
        </jmeterTestPlan>
    </xsl:template>
    
    <xsl:template match="jmx:RecentQueryHistory">
        <xsl:choose>
            <xsl:when test="$duplicates">
                <xsl:for-each select="jmx:row">
                    <xsl:sort select="xs:integer(jmx:mostRecentExecutionTime)" order="ascending"/>
                    <xsl:apply-templates select="."/>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each-group select="jmx:row" group-by="jmx:requestURI">
                    <xsl:sort select="xs:integer(jmx:mostRecentExecutionTime)" order="ascending"/>
                    <xsl:apply-templates select="current-group()[1]"/>
                </xsl:for-each-group>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="jmx:RecentQueryHistory/jmx:row">
        <HTTPSamplerProxy guiclass="HttpTestSampleGui"
            testclass="HTTPSamplerProxy"
            testname="{substring-after(jmx:requestURI, $path)}" enabled="true">
            <elementProp name="HTTPsampler.Arguments" elementType="Arguments"
                guiclass="HTTPArgumentsPanel" testclass="Arguments"
                testname="User Defined Variables" enabled="true">
                <collectionProp name="Arguments.arguments"/>
            </elementProp>
            <stringProp name="HTTPSampler.domain">${host}</stringProp>
            <stringProp name="HTTPSampler.port">${port}</stringProp>
            <stringProp name="HTTPSampler.connect_timeout"/>
            <stringProp name="HTTPSampler.response_timeout"/>
            <stringProp name="HTTPSampler.protocol">http</stringProp>
            <stringProp name="HTTPSampler.contentEncoding"/>
            <stringProp name="HTTPSampler.path">${root}<xsl:value-of select="substring-after(jmx:requestURI, $path)"/></stringProp>
            <stringProp name="HTTPSampler.method">GET</stringProp>
            <boolProp name="HTTPSampler.follow_redirects">true</boolProp>
            <boolProp name="HTTPSampler.auto_redirects">false</boolProp>
            <boolProp name="HTTPSampler.use_keepalive">true</boolProp>
            <boolProp name="HTTPSampler.DO_MULTIPART_POST">false</boolProp>
            <boolProp name="HTTPSampler.BROWSER_COMPATIBLE_MULTIPART"
                >true</boolProp>
            <boolProp name="HTTPSampler.monitor">false</boolProp>
            <stringProp name="HTTPSampler.embedded_url_re"/>
        </HTTPSamplerProxy>
        <hashTree/>
    </xsl:template>
</xsl:stylesheet>
