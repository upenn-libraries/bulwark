# -*- encoding : utf-8 -*-
class SolrDocument
  include Blacklight::Solr::Document

  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension( Blacklight::Document::Email )

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension( Blacklight::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension( Blacklight::Document::DublinCore)

  def unique_identifier
    fetch('unique_identifier_ssi', nil) || fetch('unique_identifier_tesim', []).first
  end

  # Removing circular references from relation field.
  def relation
    fetch(:relation_tesim, []).delete_if { |r| r.include?(id) }
  end

  # Return thumbnail link for Solr document
  def thumbnail_link(root_url)
    thumbnail_id = fetch(:thumbnail_asset_id_ssi, nil)

    return unless thumbnail_id

    # Url helpers escape unique identifier, so we have to manually create the links.
    URI.join(root_url, "items/#{unique_identifier}/assets/#{thumbnail_id}/thumbnail").to_s
  end

  # Returns assets that are not represented in the iiif manifest and have to be displayed a different way.
  #
  # @return [<Array<Hash>]
  def non_iiif_assets
    json = fetch(:non_iiif_asset_listing_ss, nil)

    return [] if json.blank?
    JSON.parse(json, symbolize_names: true)
  end

  # Returns true if item has a IIIF manifest
  def iiif_manifest?
    fetch('iiif_manifest_path_ss', nil).present?
  end

  # Returns true if bibnumber is present, false otherwise.
  #
  # @return [Boolean]
  def bibnumber?
    bibnumber.present?
  end

  # Returns bibnumber
  #
  # @return [String]
  def bibnumber
    fetch('bibnumber_ssi', nil)
  end
end
