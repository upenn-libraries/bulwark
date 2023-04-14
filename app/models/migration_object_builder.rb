# frozen_string_literal: true

# accumulate information about digital object into a special structured hash for consumption by Apotheca
class MigrationObjectBuilder
  class Error < StandardError; end

  EXPECTED_SHA_LENGTH = 64

  # @param [Repo] repo
  def initialize(repo)
    @repo = repo
    @assets = repo.assets
    @descriptive_metadata = repo.descriptive_metadata
    @structural_metadata = repo.structural_metadata
  end

  # @return [Hash]
  def build
    { human_readable_name: @repo.human_readable_name,
      unique_identifier: @repo.unique_identifier,
      created_at: @repo.created_at,
      created_by: @repo.created_by.email, # email - will it always be set? this could NoMethodError
      first_published_at: @repo.first_published_at,
      last_published_at: @repo.last_published_at,
      published: true,
      descriptive_metadata: descriptive_metadata,
      structural_metadata: structural_metadata,
      assets: assets }
  rescue StandardError => e
    raise MigrationObjectBuilder::Error, e.message
  end

  # @return [Hash]
  def descriptive_metadata
    keys = %w[title abstract description call_number collection contributor
              personal_name corporate_name coverage creator date format geographic_subject
              subject identifier includes item_type language notes provenance publisher
              relation rights source bibnumber]
    hash = {}
    keys.each do |field| # no index_with :/
      hash[field] = @descriptive_metadata.original_mappings[field] || [] # original_mappings not set by test factory
    end
    hash
  end

  # @return [Hash]
  def structural_metadata
    # methods defined in StructuralMetadataSources
    { viewing_hint: @structural_metadata.viewing_hint,
      viewing_direction: @structural_metadata.viewing_direction }
  end

  # @return [Hash]
  def assets
    { bucket: @repo.names.bucket,
      arranged: arranged_assets,
      unarranged: unarranged_assets }
  end

  def arranged_assets
    source = @structural_metadata.original_mappings['sequence']
    source.map do |seq|
      asset = @assets.find { |a| a.filename == seq['filename'] }
      { filename: seq['filename'],
        label: seq['label'],
        annotations: seq['table_of_contents'],
        transcription: seq['fulltext'],
        checksum: asset_checksum(asset),
        path: "#{@repo.names.bucket}%2F#{asset.access_file_location}" }
    end
  end

  # assuming @asset entries not in sequence are un-arranged
  # @return [Array]
  def unarranged_assets
    source = Array.wrap(@structural_metadata.original_mappings['sequence'])
    asset_filenames = Array.wrap(@assets.map(&:filename))
    seq_filenames = source.map { |s| s['filename'] }
    asset_filenames - seq_filenames
  end

  # extract sha256 value from original_file_location
  # @param [Asset] asset
  # @return [String,nil]
  def asset_checksum(asset)
    filename = asset.original_file_location
    sha = Array.wrap(filename.split('-')).last.split('.')&.first
    sha&.length == EXPECTED_SHA_LENGTH ? sha : nil # TODO: raise if no sha available?
  end
end
