<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
	version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:dc="http://purl.org/dc/elements/1.1/">

	<xsl:output indent="yes" method="xml" version="1.0" encoding="UTF-8"/>


	<!-- Remove blanks -->
	<xsl:template match="text()"/>


	<!-- Turn Solr documents into <record> elements and process their children -->
	<xsl:template match="doc">
		<record>
			<xsl:apply-templates match="*"/>
		</record>
	</xsl:template>


	<!-- Process Solr Arrays by iterating through all their children -->
	<xsl:template match="arr">
		<xsl:apply-templates match="."/>
	</xsl:template>


	<!-- Process Solr all field types in the same way: determine their field name and write out their value. -->
	<xsl:template match="str|int|date">
		<xsl:variable name="fieldName">
			<xsl:choose>
				<!-- This is a single element, it has a name attribute. -->
				<xsl:when test="@name">
					<xsl:value-of select="@name"/>
				</xsl:when>
				<!-- This is an element inside an array, its parent element has a name attribute -->
				<xsl:when test="../@name">
					<xsl:value-of select="../@name"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>

		<xsl:call-template name="field">
			<xsl:with-param name="originalName" select="$fieldName"/>
			<xsl:with-param name="content" select="."/>
		</xsl:call-template>
	</xsl:template>


	<!-- Template to create new fields and dump the ones we do not want. -->
	<xsl:template name="field">
		<xsl:param name="originalName"/>
		<xsl:param name="content"/>

		<xsl:variable name="newName">
			<!-- Only use fields whose names begin with 'dc.' -->
			<xsl:if test="substring($originalName, 1, 3) = 'dc.'">
				<!-- Only use fields whose names end in '.de' or '.en' -->
				<xsl:choose>
					<xsl:when test="substring($originalName, string-length($originalName) - 2, 3) = '.de'
									or substring($originalName, string-length($originalName) - 2, 3) = '.en'">
						<xsl:value-of select="substring($originalName, 4, string-length($originalName) - 6)"/>
					</xsl:when>
					<xsl:when test="$originalName = 'dc.date.issued.year'">
						<xsl:text>date.issued</xsl:text>
					</xsl:when>
					<xsl:when test="$originalName = 'dc.identifier.uri'">
						<xsl:value-of select="substring($originalName, 4)"/>
					</xsl:when>
				</xsl:choose>
			</xsl:if>
		</xsl:variable>

		<xsl:if test="$newName != ''">
			<xsl:element name="dc:{$newName}">
				<xsl:value-of select="$content"/>
			</xsl:element>
		</xsl:if>
	</xsl:template>

</xsl:stylesheet>
