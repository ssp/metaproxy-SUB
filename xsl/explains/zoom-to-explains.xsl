<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:mp="http://indexdata.com/metaproxy"
	xmlns:e="http://explain.z3950.org/dtd/2.0/"
	version="1.0">

	<xsl:output indent="yes" method="xml" version="1.0" encoding="UTF-8"/>


	<xsl:param name="hostname"/>
	<xsl:param name="port"/>



	<!-- Remove blanks. -->
	<xsl:template match="text()"/>



	<!--
		Root element:
			* create records element
			* add explain element converted from metaproxy torus records as children
	-->
	<xsl:template match="/">
		<explains>
			<xsl:apply-templates select="//mp:filter[@type='zoom']/mp:torus/mp:records/mp:record"/>
		</explains>
	</xsl:template>



	<!--
		Process Torus records to create an explain tag with:
			* serverInfo
			* databaseInfo
			* indexInfo
			* schemaInfo
			* configInfo
	-->
	<xsl:template match="//mp:filter[@type='zoom']/mp:torus/mp:records/mp:record">
		<e:explain>
			<xsl:call-template name="serverInfo"/>
			<xsl:call-template name="databaseInfo"/>
			<xsl:call-template name="indexInfo"/>
			<xsl:call-template name="schemaInfo"/>
			<xsl:call-template name="configInfo"/>
		</e:explain>
	</xsl:template>



	<!--
		Create server information with:
			* host name (if provided in the $hostName parameter)
			* port (if provided in the $port parameter)
			* database name
	-->
	<xsl:template name="serverInfo">
		<e:serverInfo protocol="SRU">
			<xsl:if test="string-length($hostname) &gt; 0">
				<e:host>
					<xsl:value-of select="$hostname"/>
				</e:host>
			</xsl:if>
			<xsl:if test="string-length($port) &gt; 0">
				<e:port>
					<xsl:value-of select="$port"/>
				</e:port>
			</xsl:if>
			<e:database>
				<xsl:value-of select="mp:udb"/>
			</e:database>
		</e:serverInfo>
	</xsl:template>



	<!--
		Create database information with:
			* information stored in the Torus record
			* pre-defined author information
	-->
	<xsl:template name="databaseInfo">
		<e:databaseInfo>
			<xsl:copy-of select="e:databaseInfo/*"/>
			<e:author>Sven-S. Porst, SUB Göttingen</e:author>
			<e:contact>porst@sub.uni-goettingen.de</e:contact>
		</e:databaseInfo>
	</xsl:template>



	<!--
		Create index information with:
			* information about the elemen sets used
	-->
	<xsl:template name="indexInfo">
		<e:indexInfo>
			<xsl:call-template name="elementSets"/>
			<xsl:call-template name="indexes"/>
		</e:indexInfo>
	</xsl:template>



	<!--
		Create schema information with:
			* Solr schema for all targets
			* DC schema if transform is used
	-->
	<xsl:template name="schemaInfo">
		<e:schemaInfo>
			<xsl:for-each select="mp:schema">
				<xsl:choose>
					<xsl:when test="@name='solr'">
						<e:schema name="solr" retrieve="true">
							<e:title>Solr</e:title>
						</e:schema>
					</xsl:when>
					<xsl:when test="@name='mets'">
						<e:schema name="mets" retrieve="true">
							<e:title>METS</e:title>
						</e:schema>
					</xsl:when>
					<xsl:when test="@name='mods'">
						<e:schema name="mods" retrieve="true">
							<e:title>MODS</e:title>
						</e:schema>
					</xsl:when>
					<xsl:when test="@name='dc'">
						<e:schema name="dc" retrieve="true" identifier="http://www.loc.gov/zing/srw/dcschema/v1.0/">
							<e:title>Dublin Core</e:title>
						</e:schema>
					</xsl:when>
					<xsl:when test="@name='marcxml'">
						<e:schema name="marcxml" retrieve="true" identifier="info:srw/schema/1/marcxml-v1.1">
							<e:title>MARC</e:title>
						</e:schema>
					</xsl:when>
					<xsl:when test="@name='turbomarc'">
						<e:schema name="turbomarc" retrieve="true">
							<e:title>TurboMARC</e:title>
						</e:schema>
					</xsl:when>
				</xsl:choose>
			</xsl:for-each>
		</e:schemaInfo>
	</xsl:template>



	<!--
		Create configuration information.
	-->
	<xsl:template name="configInfo">
		<e:configInfo>
			<e:default type="contextSet">cql</e:default>
			<e:default type="index">serverChoice</e:default>
			<e:default type="relation">=</e:default>
		</e:configInfo>
	</xsl:template>



	<!--
		Analyse which element sets are used in the current records and insert
		tags for them.
	-->
	<xsl:template name="elementSets">
		<xsl:variable name="setNames">
			<xsl:for-each select="./*">
				<xsl:variable name="fieldName" select="substring-after(local-name(.), 'cclmap_')"/>
				<xsl:if test="string-length($fieldName) &gt; 0">
					<xsl:for-each select="//mp:filter[@type='zoom']/mp:fieldmap">
						<xsl:variable name="elementSet" select="substring-before(@cql, '.')"/>
						<xsl:variable name="indexName" select="substring-after(@cql, '.')"/>
						<xsl:variable name="cclName">
							<xsl:choose>
								<xsl:when test="@ccl"><xsl:value-of select="@ccl"/></xsl:when>
								<xsl:otherwise>term</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:if test="$fieldName = $cclName">
							<xsl:value-of select="$elementSet"/>
							<xsl:text>*</xsl:text>
						</xsl:if>
					</xsl:for-each>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>

		<xsl:call-template name="elementSetTags">
			<xsl:with-param name="setNames" select="$setNames"/>
		</xsl:call-template>
	</xsl:template>



	<!--
		Create tags for element sets: the parameter string contains the names
		of all strings used in this service. If we have a <set> record for a name
		contained in the string, add it.
	-->
	<xsl:template name="elementSetTags">
		<xsl:param name="setNames"/>
		<xsl:if test="contains($setNames, 'cql*')">
			<e:set name="cql" identifier="info:srw/cql-context-set/1/cql-v1.2">
				<e:title>CQL Standard Set</e:title>
			</e:set>
		</xsl:if>
		<xsl:if test="contains($setNames, 'rec*')">
			<e:set name="rec" identifier="info:srw/cql-context-set/2/rec-1.1">
				<e:title>Records Standard Set</e:title>
			</e:set>
		</xsl:if>
		<xsl:if test="contains($setNames, 'dc*')">
			<e:set name="dc" identifier="info:srw/cql-context-set/1/dc-v1.1">
				<e:title>Dublin Core Set with custom extensions</e:title>
			</e:set>
		</xsl:if>
		<xsl:if test="contains($setNames, 'zvdd*')">
			<e:set name="zvdd">
				<e:title>ZVDD Custom Set</e:title>
			</e:set>
		</xsl:if>
	</xsl:template>



	<!--
		Create tags for indexes: collect information from the fieldmaps and cclmap_*
		fields and assemble them to create the relevant <index> tags.
	-->
	<xsl:template name="indexes">
		<xsl:for-each select="./*">
			<xsl:variable name="fieldName" select="substring-after(local-name(.), 'cclmap_')"/>
			<xsl:if test="string-length($fieldName) &gt; 0">
				<xsl:for-each select="//mp:filter[@type='zoom']/mp:fieldmap">
					<xsl:variable name="elementSet" select="substring-before(@cql, '.')"/>
					<xsl:variable name="indexName" select="substring-after(@cql, '.')"/>
					<xsl:variable name="cclName">
						<xsl:choose>
							<xsl:when test="@ccl"><xsl:value-of select="@ccl"/></xsl:when>
							<xsl:otherwise>term</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:if test="$fieldName = $cclName">
						<e:index search="true" scan="false" sort="false">
							<e:title>
								<xsl:value-of select="mp:title"/>
							</e:title>
							<e:map>
								<e:name set="{$elementSet}">
									<xsl:value-of select="$indexName"/>
								</e:name>
							</e:map>
						</e:index>
					</xsl:if>
				</xsl:for-each>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	
	
	
	<!--
		Template to Search & Replace in a string.
	-->
	<xsl:template name="string-replace">
		<xsl:param name="string"/>
		<xsl:param name="search"/>
		<xsl:param name="replace"/>

		<xsl:choose>
			<xsl:when test="contains($string, $search)">
				<xsl:value-of select="substring-before($string, $search)"/>
				<xsl:value-of select="$replace"/>
				<xsl:call-template name="string-replace">
					<xsl:with-param name="string" select="substring-after($string, $search)"/>
					<xsl:with-param name="search" select="$search"/>
					<xsl:with-param name="replace" select="$replace"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$string"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


</xsl:stylesheet>
