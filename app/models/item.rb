# frozen_string_literal: true

# Class to find, create and delete Items.
class Item
  REQUIRED_CREATE_KEYS = %w[id uuid first_published_at last_published_at].freeze

  # Find item.
  #
  # @return [SolrDocument] if Item is found
  # @return [FalseClass] if Item is not found
  def self.find(ark)
    response = Blacklight.default_index.search(q: "unique_identifier_ssi:\"#{ark}\"", fq: ['from_apotheca_bsi:true'])
    return if response.docs.count.zero?
    response.docs.first
  end

  # Add Item to Solr.
  def self.create(payload)
    missing_keys = REQUIRED_CREATE_KEYS - payload.keys
    raise ArgumentError, "Payload is missing the following key(s): #{missing_keys.join(', ')}." if missing_keys.present?

    document = {
      id: solr_identifier(payload[:id]),
      uuid_ssi: payload[:uuid],
      unique_identifier_ssi: payload[:id],
      system_create_dtsi: payload[:first_published_at],
      system_modified_dtsi: payload[:last_published_at],
      thumbnail_asset_id_ssi: payload[:thumbnail_asset_id],
      bibnumber_ssi: payload.dig(:descriptive_metadata, :bibnumber, 0, :value),
      iiif_manifest_path_ss: payload[:iiif_manifest_path],
      from_apotheca_bsi: 'T',
      non_iiif_asset_listing_ss: payload.fetch(:assets, []).select { |a| !a[:iiif] }.to_json, # Assets that need to be listed instead of displayed via the IIIF manifest.
      raw_ss: payload.to_json # Keep the whole payload
    }

    payload.fetch(:descriptive_metadata, []).each do |field, values|
      next if values.blank?

      only_values = values.map { |v| v[:value] }

      document["#{field}_tesim"] = only_values
      document["#{field}_ssim"] = only_values
      document["#{field}_sim"] = only_values
      # TODO: might need to do something different for rights
    end

    # Add Solr document.
    solr = RSolr.connect(url: Settings.solr.url)
    solr.add(document)
    solr.commit
  end

  # Delete Item from Solr.
  def self.delete(ark)
    solr = RSolr.connect(url: Settings.solr.url)
    solr.delete_by_query "id:#{solr_identifier(ark)}"
    solr.commit
  end

  def self.solr_identifier(ark)
    ark.tr('ark:/', '').tr('/', '-')
  end
end
