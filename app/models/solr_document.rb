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
  def thumbnail_link
    if from_apotheca?
      thumbnail_id = fetch(:thumbnail_asset_id_ssi, nil)
      # Url helpers escape unique identifier, so we have to manually create the links.
      thumbnail_id ? "#{Rails.application.routes.url_helpers.root_url}items/#{unique_identifier}/assets/#{thumbnail_id}/thumbnail" : nil
    elsif fetch(:thumbnail_location_ssi, nil) # Fetching thumbnail location from Solr document if present.
      thumbnail_location = fetch(:thumbnail_location_ssi, nil)&.split('/', 2)
      Bulwark::Storage.url_for(*thumbnail_location)
    else # Fetching thumbnail location from database.
      repo = Repo.find_by(unique_identifier: unique_identifier)
      repo.thumbnail_link
    end
  end

  # Returns assets that are not represented in the iiif manifest and have to be displayed a different way.
  #
  # @return [<Array<Hash>>]
  def non_iiif_assets
    json = fetch(:non_iiif_asset_listing_ss, nil)

    return [] if json.blank?
    JSON.parse(json, symbolize_names: true)
  end

  # Returns true if this item was published from Apotheca.
  def from_apotheca?
    fetch('from_apotheca_bsi', false)
  end
end
