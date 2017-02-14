<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  xmlns:ex="http://exslt.org/dates-and-times"
  xmlns:sv="http://www.jcp.org/jcr/sv/1.0"
  xmlns:image="http://www.modeshape.org/images/1.0"
  xmlns:space="preserve"
  extension-element-prefixes="exsl ex">
  <xsl:variable name="uuid">
    <xsl:value-of select="/root/record/uuid" />
  </xsl:variable>
  <xsl:output method="xml" indent="yes"/>
  <xsl:preserve-space elements="sv:node sv:property sv:value"/>
    <xsl:template match="/root/record">
      <xsl:copy>
        <exsl:document method="xml" href="fedora.xml">
          <sv:node xmlns:premis="http://www.loc.gov/premis/rdf/v1#"
            xmlns:image="http://www.modeshape.org/images/1.0"
            xmlns:sv="http://www.jcp.org/jcr/sv/1.0"
            xmlns:test="info:fedora/test/"
            xmlns:nt="http://www.jcp.org/jcr/nt/1.0"
            xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
            xmlns:ns001="info:fedora/fedora-system:def/model#"
            xmlns:ns002="http://purl.org/dc/terms/"
            xmlns:ns003="http://pcdm.org/models#"
            xmlns:ns004="http://library.upenn.edu/pqc/ns/"
            xmlns:space="preserve"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns:mode="http://www.modeshape.org/1.0"
            xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
            xmlns:fedora="http://fedora.info/definitions/v4/repository#"
            xmlns:jcr="http://www.jcp.org/jcr/1.0"
            xmlns:ebucore="http://www.ebu.ch/metadata/ontologies/ebucore/ebucore#"
            xmlns:ldp="http://www.w3.org/ns/ldp#"
            xmlns:xs="http://www.w3.org/2001/XMLSchema"
            xmlns:fedoraconfig="http://fedora.info/definitions/v4/config#"
            xmlns:mix="http://www.jcp.org/jcr/mix/1.0"
            xmlns:foaf="http://xmlns.com/foaf/0.1/"
            xmlns:dc="http://purl.org/dc/elements/1.1/">
            <xsl:attribute name="sv:name"><xsl:value-of select="translate(substring-after($uuid,'ark:/'),'/','-')" /></xsl:attribute>
          <sv:property sv:name="jcr:primaryType" sv:type="Name">
            <sv:value>nt:folder</sv:value>
          </sv:property>
          <sv:property sv:name="jcr:mixinTypes" sv:type="Name" sv:multiple="false">
            <sv:value>fedora:Container</sv:value>
            <sv:value>fedora:Resource</sv:value>
          </sv:property>
          <sv:property sv:name="jcr:lastModifiedBy" sv:type="String">
            <sv:value>bypassAdmin</sv:value>
          </sv:property>
          <sv:property sv:name="ns001:hasModel" sv:type="String" sv:multiple="false">
            <sv:value>Manuscript</sv:value>
          </sv:property>
          <sv:property sv:name="jcr:createdBy" sv:type="String">
            <sv:value>bypassAdmin</sv:value>
          </sv:property>
          <sv:property sv:name="ns004:file_list" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="file_list/file" />
          </sv:property>

          <sv:property sv:name="ns004:uniqueIdentifier" sv:type="String" sv:multiple="false">
              <sv:value><xsl:value-of select="$uuid" /></sv:value>
          </sv:property>

          <sv:property sv:name="ns002:title" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="manuscript_name" />
          </sv:property>

          <sv:property sv:name="ns004:administrativeContact" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="administrative_contact" />
          </sv:property>

          <sv:property sv:name="ns004:administrativeContactEmail" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="administrative_contact_email" />
          </sv:property>

          <sv:property sv:name="ns004:metadataCreator" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="metadata_creator" />
          </sv:property>

          <sv:property sv:name="ns004:metadataCreatorEmail" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="metadata_creator_email" />
          </sv:property>

          <sv:property sv:name="ns004:repositoryCountry" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="repository_country" />
          </sv:property>

          <sv:property sv:name="ns004:repositoryCity" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="repository_city" />
          </sv:property>

          <sv:property sv:name="ns004:holdingInstitution" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="holding_institution" />
          </sv:property>

          <sv:property sv:name="ns004:repositoryName" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="repository_name" />
          </sv:property>

          <sv:property sv:name="ns004:sourceCollection" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="source_collection" />
          </sv:property>

          <sv:property sv:name="ns004:callNumberid" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="call_numberid" />
          </sv:property>

          <sv:property sv:name="ns004:recordUrl" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="record_url" />
          </sv:property>

          <sv:property sv:name="ns004:alternateId" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="alternate_id" />
          </sv:property>

          <sv:property sv:name="ns004:alternateIdType" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="alternate_id_type" />
          </sv:property>

          <sv:property sv:name="ns004:manuscriptName" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="manuscript_name" />
          </sv:property>

          <sv:property sv:name="ns004:authorName" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="author_name" />
          </sv:property>

          <sv:property sv:name="ns004:authorUri" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="author_uri" />
          </sv:property>

          <sv:property sv:name="ns004:translatorName" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="translator_name" />
          </sv:property>

          <sv:property sv:name="ns004:translatorUri" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="translator_uri" />
          </sv:property>

          <sv:property sv:name="ns004:artistName" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="artist_name" />
          </sv:property>

          <sv:property sv:name="ns004:artistUri" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="artist_uri" />
          </sv:property>

          <sv:property sv:name="ns004:formerOwnerName" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="former_owner_name" />
          </sv:property>

          <sv:property sv:name="ns004:formerOwnerUri" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="former_owner_uri" />
          </sv:property>

          <sv:property sv:name="ns004:provenance" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="provenance" />
          </sv:property>

          <sv:property sv:name="ns004:dateSingle" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="date_single" />
          </sv:property>

          <sv:property sv:name="ns004:dateRangeStart" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="date_range_start" />
          </sv:property>

          <sv:property sv:name="ns004:dateRangeEnd" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="date_range_end" />
          </sv:property>

          <sv:property sv:name="ns004:dateNarrative" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="date_narrative" />
          </sv:property>

          <sv:property sv:name="ns004:placeOfOrigin" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="place_of_origin" />
          </sv:property>

          <sv:property sv:name="ns004:originDetails" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="origin_details" />
          </sv:property>

          <sv:property sv:name="ns002:description" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="description" />
          </sv:property>

          <sv:property sv:name="ns002:language" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="language" />
          </sv:property>

          <sv:property sv:name="ns004:foliationPagination" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="foliation_pagination" />
          </sv:property>

          <sv:property sv:name="ns004:flyleavesAndLeaves" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="flyleaves_and_leaves" />
          </sv:property>

          <sv:property sv:name="ns004:layout" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="layout" />
          </sv:property>

          <sv:property sv:name="ns004:colophon" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="colophon" />
          </sv:property>

          <sv:property sv:name="ns004:collation" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="collation" />
          </sv:property>

          <sv:property sv:name="ns004:script" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="script" />
          </sv:property>

          <sv:property sv:name="ns004:decoration" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="decoration" />
          </sv:property>

          <sv:property sv:name="ns004:binding" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="binding" />
          </sv:property>

          <sv:property sv:name="ns004:watermarks" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="watermarks" />
          </sv:property>

          <sv:property sv:name="ns004:catchwords" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="catchwords" />
          </sv:property>

          <sv:property sv:name="ns004:signatures" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="signatures" />
          </sv:property>

          <sv:property sv:name="ns004:notes" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="notes" />
          </sv:property>

          <sv:property sv:name="ns004:supportMaterial" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="support_material" />
          </sv:property>

          <sv:property sv:name="ns004:pageDimensions" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="page_dimensions" />
          </sv:property>

          <sv:property sv:name="ns004:boundDimensions" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="bound_dimensions" />
          </sv:property>

          <sv:property sv:name="ns004:relatedResource" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="related_resource" />
          </sv:property>

          <sv:property sv:name="ns004:relatedResourceUrl" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="related_resource_url" />
          </sv:property>

          <sv:property sv:name="ns004:subjectNames" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="subject_names" />
          </sv:property>

          <sv:property sv:name="ns004:subjectNamesUri" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="subject_names_uri" />
          </sv:property>

          <sv:property sv:name="ns004:subjectTopical" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="subject_topical" />
          </sv:property>

          <sv:property sv:name="ns004:subjectTopicalUri" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="subject_topical_uri" />
          </sv:property>

          <sv:property sv:name="ns004:subjectGeographic" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="subject_geographic" />
          </sv:property>

          <sv:property sv:name="ns004:subjectGeographicUri" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="subject_geographic_uri" />
          </sv:property>

          <sv:property sv:name="ns004:subjectGenreForm" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="subject_genre_form" />
          </sv:property>

          <sv:property sv:name="ns004:subjectGenreFormUri" sv:type="String" sv:multiple="false">
            <xsl:apply-templates select="subject_genre_form_uri" />
          </sv:property>

          <xsl:apply-templates select="pages/page" />
          </sv:node>
        </exsl:document>
      </xsl:copy>
    </xsl:template>

    <xsl:template match="administrative_contact">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="administrative_contact_email">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="metadata_creator">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="metadata_creator_email">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="repository_country">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="repository_city">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="holding_institution">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="repository_name">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="source_collection">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="call_numberid">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="record_url">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="alternate_id">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="alternate_id_type">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="manuscript_name">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="author_name">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="author_uri">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="translator_name">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="translator_uri">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="artist_name">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="artist_uri">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="former_owner_name">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="former_owner_uri">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="provenance">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="date_single">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="date_range_start">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="date_range_end">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="date_narrative">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="place_of_origin">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="origin_details">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="description">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="language">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="foliation_pagination">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="flyleaves_and_leaves">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="layout">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="colophon">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="collation">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="script">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="decoration">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="binding">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="watermarks">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="catchwords">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="signatures">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="notes">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="support_material">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="page_dimensions">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="bound_dimensions">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="related_resource">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="related_resource_url">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="subject_names">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="subject_names_uri">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="subject_topical_uri">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="subject_geographic">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="subject_geographic_uri">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="subject_genre_form">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>

    <xsl:template match="subject_genre_form_uri">
      <sv:value><xsl:apply-templates /></sv:value>
    </xsl:template>



    <xsl:template match="pages/page">
      <sv:node>
      <xsl:attribute name="sv:name">
        <xsl:value-of select="format-number(serial_num, '00000')" />
      </xsl:attribute>
      <sv:property sv:name="jcr:primaryType" sv:type="Name">
        <sv:value>nt:folder</sv:value>
      </sv:property>
      <sv:property sv:name="jcr:mixinTypes" sv:type="Name" sv:multiple="false">
        <sv:value>fedora:Container</sv:value>
        <sv:value>fedora:Resource</sv:value>
      </sv:property>
      <sv:property sv:name="jcr:lastModifiedBy" sv:type="String">
        <sv:value>bypassAdmin</sv:value>
      </sv:property>
      <sv:property sv:name="ns001:hasModel" sv:type="String" sv:multiple="false">
        <sv:value>Image</sv:value>
      </sv:property>
      <sv:property sv:name="jcr:createdBy" sv:type="String">
        <sv:value>bypassAdmin</sv:value>
      </sv:property>

      <sv:property sv:name="ns004:uniqueIdentifier" sv:type="String" sv:multiple="false">
        <sv:value><xsl:value-of select="concat($uuid, '/', format-number(serial_num, '00000'))" /></sv:value>
      </sv:property>

      <sv:property sv:name="ns004:parentManuscript" sv:type="String" sv:multiple="false">
        <sv:value><xsl:value-of select="$uuid" /></sv:value>
      </sv:property>

      <sv:property sv:name="ns004:pageNumber" sv:type="String" sv:multiple="false">
        <sv:value><xsl:value-of select="serial_num" /></sv:value>
      </sv:property>

      <sv:property sv:name="ns004:serialNum" sv:type="String" sv:multiple="false">
        <sv:value><xsl:value-of select="serial_num" /></sv:value>
      </sv:property>

      <sv:property sv:name="ns004:displayPage" sv:type="String" sv:multiple="false">
        <sv:value><xsl:value-of select="display_page" /></sv:value>
      </sv:property>

      <sv:property sv:name="ns004:fileName" sv:type="String" sv:multiple="false">
        <sv:value><xsl:value-of select="file_name" /></sv:value>
      </sv:property>

      <sv:property sv:name="ns004:tag1" sv:type="String" sv:multiple="false">
        <sv:value><xsl:value-of select="tag1" /></sv:value>
      </sv:property>

      <sv:property sv:name="ns004:value1" sv:type="String" sv:multiple="false">
        <sv:value><xsl:value-of select="value1" /></sv:value>
      </sv:property>

      <sv:property sv:name="ns004:tag2" sv:type="String" sv:multiple="false">
        <sv:value><xsl:value-of select="tag2" /></sv:value>
      </sv:property>

      <sv:property sv:name="ns004:value2" sv:type="String" sv:multiple="false">
        <sv:value><xsl:value-of select="value2" /></sv:value>
      </sv:property>

      <sv:property sv:name="ns004:tag3" sv:type="String" sv:multiple="false">
        <sv:value><xsl:value-of select="tag3" /></sv:value>
      </sv:property>

      <sv:property sv:name="ns004:value3" sv:type="String" sv:multiple="false">
        <sv:value><xsl:value-of select="value3" /></sv:value>
      </sv:property>

      <sv:property sv:name="ns004:tag4" sv:type="String" sv:multiple="false">
        <sv:value><xsl:value-of select="tag4" /></sv:value>
      </sv:property>

      <sv:property sv:name="ns004:value4" sv:type="String" sv:multiple="false">
        <sv:value><xsl:value-of select="value4" /></sv:value>
      </sv:property>

      <sv:property sv:name="ns004:tag5" sv:type="String" sv:multiple="false">
        <sv:value><xsl:value-of select="tag5" /></sv:value>
      </sv:property>

      <sv:property sv:name="ns004:value5" sv:type="String" sv:multiple="false">
        <sv:value><xsl:value-of select="value5" /></sv:value>
      </sv:property>

      <sv:property sv:name="ns004:tag6" sv:type="String" sv:multiple="false">
        <sv:value><xsl:value-of select="tag6" /></sv:value>
      </sv:property>

      <sv:property sv:name="ns004:value6" sv:type="String" sv:multiple="false">
        <sv:value><xsl:value-of select="value6" /></sv:value>
      </sv:property>

    </sv:node>
  </xsl:template>

  <xsl:template match="file_name">
    <sv:value><xsl:apply-templates /></sv:value>
  </xsl:template>

</xsl:stylesheet>
