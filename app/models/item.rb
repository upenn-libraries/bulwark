# frozen_string_literal: true

# Class to find, create and delete Items.
#
# Each item has a representation in the database (which includes the full json payload we receive) and in Solr (which
# includes the data that is used for display).
class Item < ActiveRecord::Base
  REQUIRED_KEYS = %w[id uuid first_published_at last_published_at].freeze

  validates :unique_identifier, :published_json, presence: true
  validates :unique_identifier, uniqueness: true
  validate :required_keys_present

  serialize :published_json, JSON

  # Fetch nested asset record.
  #
  # @param [String] id
  # @return [Hash]
  def asset(id)
    published_json['assets']&.find { |a| a['id'] == id }
  end

  # Ensuring the minimum required fields are present in the published_json
  def required_keys_present
    return if published_json.blank?

    missing_keys = REQUIRED_KEYS - published_json.keys

    return if missing_keys.blank?

    errors.add(:published_json, "missing the following key(s): #{missing_keys.join(', ')}")
  end

  # Add Item to Solr.
  def add_solr_document!
    raise ArgumentError, 'publish_json must be present in order to add document to Solr' if published_json.blank?

    solr = RSolr.connect(url: Settings.solr.url)
    solr.add(solr_document)
    solr.commit
  end

  # Delete Item from Solr.
  def remove_solr_document!
    solr = RSolr.connect(url: Settings.solr.url)
    solr.delete_by_query "id:#{solr_identifier}"
    solr.commit
  end

  def solr_identifier
    unique_identifier.gsub('ark:/', '').tr('/', '-')
  end

  # Returns Solr document that can be committed to Solr
  #
  # @return [Hash] solr_document
  def solr_document
    document = {
      id: solr_identifier,
      uuid_ssi: published_json['uuid'],
      unique_identifier_ssi: published_json['id'],
      system_create_dtsi: published_json['first_published_at'],
      system_modified_dtsi: published_json['last_published_at'],
      thumbnail_asset_id_ssi: published_json['thumbnail_asset_id'],
      bibnumber_ssi: published_json.dig('descriptive_metadata', 'bibnumber', 0, 'value'),
      iiif_manifest_path_ss: published_json['iiif_manifest_path'],
      pdf_path_ss: published_json['pdf_path'],
      pdf_manifest_path_ss: published_json['pdf_path'],
      from_apotheca_bsi: 'T',
      non_iiif_asset_listing_ss: published_json.fetch('assets', []).select { |a| !a['iiif'] }.to_json # Assets that need to be listed instead of displayed via the IIIF manifest.
    }

    descriptive_metadata = {
      creator: [], creator_with_role: [], contributor: [], contributor_with_role: [], name: []
    }

    # Extract the values that we want to display from the descriptive metadata.
    published_json.fetch('descriptive_metadata', []).each do |field, values|
      next if values.blank?

      case field
      when 'date'
        dates = values&.map { |v| v['value'] }

        descriptive_metadata[field] = dates&.map do |value|
          if value =~ /^\d\d(\d|X)X$/
            "#{value.tr('X', '0')}s"
          else
            value
          end
        end

        descriptive_metadata['year'] = dates&.sum([]) do |value|
          if value =~ /^\d\d(\d|X)X$/ # 10XX, 100X
            Range.new(value.tr('X', '0').to_i, value.tr('X', '9').to_i).to_a.map(&:to_s)
          elsif value =~ /^\d\d\d\d(-\d\d(-\d\d)?)?$/ # 2002, 2002-02, 2002-02-02
            Array.wrap(value[0..3])
          else
            [value]
          end
        end
      when 'rights' # extracting URI for rights
        descriptive_metadata[:rights] = values.map { |v| v['uri'] }
      when 'name' # extracting creator, contributor names based on roles
        values.each do |name|
          roles = name.fetch('role', []).map { |r| r['value'] }.map(&:downcase).uniq
          name_with_role = roles.blank? ? name['value'] : "#{name['value']} (#{roles.join(', ')})"

          if roles.include?('creator') || roles.include?('author')
            descriptive_metadata[:creator] << name['value']
            descriptive_metadata[:creator_with_role] << name_with_role
          elsif roles.present?
            descriptive_metadata[:contributor] << name['value']
            descriptive_metadata[:contributor_with_role] << name_with_role
          else
            descriptive_metadata[:name] << name['value']
          end
        end
      else
        descriptive_metadata[field] = values&.map { |v| v['value'] }
      end
    end

    descriptive_metadata.each do |field, values|
      document[:"#{field}_tesim"] = values
      document[:"#{field}_ssim"] = values
      document[:"#{field}_sim"] = values
    end

    document
  end

  # Find item in Solr.
  #
  # @return [SolrDocument] if Item is found
  # @return [FalseClass] if Item is not found
  def self.find_solr_document(ark)
    response = Blacklight.default_index.search(q: "unique_identifier_ssi:\"#{ark}\"", fq: ['from_apotheca_bsi:true'])
    return if response.docs.count.zero?
    response.docs.first
  end
end
