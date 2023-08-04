# frozen_string_literal: true

# Accumulate information about digital object into a special structured hash for consumption by Apotheca
class MigrationObjectBuilder
  class Error < StandardError; end

  # @param [Repo] repo
  def initialize(repo)
    @repo = repo
    @assets = repo.assets
    @descriptive_metadata = repo.descriptive_metadata
    @structural_metadata = repo.structural_metadata
  end

  # @return [Hash]
  def build
    {
      human_readable_name: @repo.human_readable_name,
      unique_identifier: @repo.unique_identifier,
      created_at: @repo.created_at,
      created_by: @repo.created_by.email,
      first_published_at: @repo.first_published_at,
      last_published_at: @repo.last_published_at,
      published: true,
      descriptive_metadata: descriptive_metadata,
      structural_metadata: structural_metadata,
      assets: {
        bucket: @repo.names.bucket,
        arranged: arranged_assets,
        unarranged: unarranged_assets
      }
    }
  rescue StandardError => e
    raise MigrationObjectBuilder::Error, e.message
  end

  # @return [Hash]
  def descriptive_metadata
    @descriptive_metadata.original_mappings
  end

  # @return [Hash]
  def structural_metadata
    # methods defined in StructuralMetadataSources
    { viewing_hint: @structural_metadata.viewing_hint(default: nil),
      viewing_direction: @structural_metadata.viewing_direction(default: nil) }
  end

  def arranged_assets
    source = @structural_metadata.original_mappings['sequence']
    assets(source)
  end

  # assuming @asset entries not in sequence are un-arranged
  # @return [Array]
  def unarranged_assets
    asset_filenames = Array.wrap(@assets.map(&:filename))
    seq_filenames = Array.wrap(@structural_metadata.original_mappings['sequence']).map { |s| s['filename'] }

    source = (asset_filenames - seq_filenames).map { |s| { 'filename' => s } }

    assets(source)
  end

  def assets(source)
    source&.map do |seq|
      asset = @assets.find { |a| a.filename == seq['filename'] }
      { filename: seq['filename'],
        label: seq['label'],
        annotation: seq.fetch('table_of_contents', []),
        transcription: [seq['fulltext']].compact,
        checksum: asset_checksum(asset),
        path: asset.original_file_location }
    end
  end

  # Extract sha256 value from original_file_location
  # @param [Asset] asset
  # @return [String,nil]
  def asset_checksum(asset)
    filename = asset.original_file_location
    match = filename.match(/\ASHA256E-s\d*--(\h{64})\.[a-zA-Z]+\Z/)
    match ? match[1] : nil
  end
end
