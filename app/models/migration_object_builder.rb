# frozen_string_literal: true

# accumulate information about digital object into a special structured hash for consumption by Apotheca
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
    {
      bucket: '',
      arranged: arranged_assets,
      unarranged: unarranged_assets
    }
  end

  def arranged_assets
    source = @structural_metadata.user_defined_mappings['sequence']
    source.map do |seq|
      {
        filename: seq['filename'], # original filename
        label: seq['label'],
        annotations: seq['table_of_contents'],
        transcription: seq['fulltext'], # not set by test factory...
        checksum: '', # TODO: existing or computed? should we fixity check at migration?
        path: '' # "path to file in the bucket, won't actually be a path just a filename"
      }
    end
  end

  def unarranged_assets
    [] # just an array of filenames
  end
end
