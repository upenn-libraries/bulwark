<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  xmlns:ex="http://exslt.org/dates-and-times"
  xmlns:image="http://www.modeshape.org/images/1.0"
  xmlns:space="preserve"
  extension-element-prefixes="exsl ex"
  xmlns:METS="http://www.loc.gov/METS/"
  xmlns:mods="http://www.loc.gov/mods/v3">
  <xsl:variable name="uuid">
    <xsl:value-of select="/root/record/uuid" />
  </xsl:variable>
  <xsl:output method="xml" indent="yes"/>
  <xsl:template match="/root/record">
    <xsl:copy>
      <exsl:document method="xml" href="mets.xml">
        <METS:mets
          xmlns:METS="http://www.loc.gov/METS/"
          xmlns:mods="http://www.loc.gov/mods/v3"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://www.loc.gov/METS/ http://www.loc.gov/standards/mets/mets.xsd http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-0.xsd">
          <xsl:attribute name="OBJID"><xsl:value-of select="$uuid" /></xsl:attribute>
          <METS:metsHdr CREATEDATE="2004-10-28T00:00:00.001" LASTMODDATE="2004-10-28T00:00:00.001">
            <METS:agent ROLE="CREATOR" TYPE="ORGANIZATION">
              <METS:name>University of Pennsylvania Libraries</METS:name>
            </METS:agent>
          </METS:metsHdr>
          <METS:dmdSec ID="DM1">
            <METS:mdWrap MDTYPE="MODS">
              <METS:xmlData>
                <mods:mods>
                  <mods:titleInfo>
                    <xsl:apply-templates select="title" />
                  </mods:titleInfo>
                  <mods:originInfo>
                    <mods:issuance>monographic</mods:issuance>
                  </mods:originInfo>
                  <mods:language>
                    <xsl:apply-templates select="language" />
                  </mods:language>
                  <mods:name type="personal">
                    <xsl:apply-templates select="personal_name" />
                  </mods:name>
                  <mods:name type="corporate">
                    <xsl:apply-templates select="corporate_name" />
                  </mods:name>
                  <mods:subject>
                    <xsl:apply-templates select="subject" />
                  </mods:subject>
                  <mods:subject>
                    <xsl:apply-templates select="geographic_subject" />
                  </mods:subject>
                  <mods:physicalDescription>
                    <mods:extent><xsl:apply-templates select="description" /></mods:extent>
                    <mods:digitalOrigin>reformatted digital</mods:digitalOrigin>
                    <mods:reformattingQuality>preservation</mods:reformattingQuality>
                    <mods:form authority="marcform" authorityURI="http://www.loc.gov/standards/valuelist/marcform.html">print</mods:form>
                  </mods:physicalDescription>
                  <mods:abstract displayLabel="Summary"><xsl:apply-templates select="abstract" /></mods:abstract>
                  <mods:note type="bibliography"><xsl:apply-templates select="bibliography_note"/></mods:note>
                  <mods:note type="citation/reference"><xsl:apply-templates select="citation_note"/></mods:note>
                  <mods:note type="ownership"><xsl:apply-templates select="ownership_note"/></mods:note>
                  <mods:note type="preferred citation"><xsl:apply-templates select="preferred_citation_note"/></mods:note>
                  <mods:note type="additional physical form"><xsl:apply-templates select="additional_physical_form_note"/></mods:note>
                  <mods:note type="publications"><xsl:apply-templates select="publications_note"/></mods:note>
                  <mods:identifier type="uuid"><xsl:value-of select="$uuid" /></mods:identifier>
                </mods:mods>
              </METS:xmlData>
            </METS:mdWrap>
          </METS:dmdSec>
        </METS:mets>
      </exsl:document>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="title">
    <mods:title><xsl:apply-templates /></mods:title>
  </xsl:template>

  <xsl:template match="language">
    <mods:languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2.html" valueURI="http://id.loc.gov/vocabulary/iso639-2/ita">
      <xsl:apply-templates />
    </mods:languageTerm>
  </xsl:template>

  <xsl:template match="abstract">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="description">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="personal_name">
    <mods:namePart><xsl:apply-templates /></mods:namePart>
  </xsl:template>

  <xsl:template match="corporate_name">
    <mods:namePart><xsl:apply-templates /></mods:namePart>
  </xsl:template>

  <xsl:template match="subject">
    <mods:topic><xsl:apply-templates /></mods:topic>
  </xsl:template>

  <xsl:template match="geographic_subject">
    <mods:geographic><xsl:apply-templates /></mods:geographic>
  </xsl:template>

  <xsl:template match="bibliography_note">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="citation_note">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="ownership_note">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="preferred_citation_note">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="additional_physical_form_note">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="publications_note">
    <xsl:apply-templates />
  </xsl:template>

</xsl:stylesheet>
