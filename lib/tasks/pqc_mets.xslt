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
            <METS:agent ROLE="CREATOR">
              <METS:name>University of Pennsylvania Libraries</METS:name>
            </METS:agent>
          </METS:metsHdr>
          <METS:dmdSec ID="DM1">
            <METS:mdWrap MDTYPE="MODS">
              <METS:xmlData>
                <mods:mods>
                  <xsl:attribute name="ID"><xsl:value-of select="$uuid"/></xsl:attribute>
                  <mods:titleInfo>
                    <xsl:apply-templates select="title" />
                  </mods:titleInfo>
                  <mods:typeOfResource>notate</mods:typeOfResource>
                  <mods:originInfo>
                    <mods:issuance>monographic</mods:issuance>
                  </mods:originInfo>
                  <mods:language>
                    <mods:languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2.html" valueURI="http://id.loc.gov/vocabulary/iso639-2/ita">
                      Italian
                    </mods:languageTerm>
                  </mods:language>

                  <mods:physicalDescription>
                                <mods:extent>101 leaves</mods:extent>
                                <mods:digitalOrigin>digitized book</mods:digitalOrigin>
                                <mods:reformattingQuality>preservation</mods:reformattingQuality>
                                <mods:form authority="marcform" authorityURI="http://www.loc.gov/standards/valuelist/marcform.html">print</mods:form>
                  </mods:physicalDescription>

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
</xsl:stylesheet>
