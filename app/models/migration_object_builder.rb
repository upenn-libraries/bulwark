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

  def build
    {
      human_readable_name: '',
      unique_identifier: '',
      created_at: '',
      created_by: '', # email
      first_published_at: '',
      last_published_at: '',
      published: true,
      descriptive_metadata: descriptive_metadata,
      structural_metadata: structural_metadata,
      assets: assets
    }
  end

  # @return [Hash]
  def descriptive_metadata
    {
      title: [],
      abstract: [],
      description: [],
      call_number: [],
      collection: [],
      contributor: [],
      personal_name: [],
      corporate_name: [],
      coverage: [],
      creator: [],
      date: [],
      format: [],
      geographic_subject: [],
      subject: [],
      identifier: [],
      includes: [],
      item_type: [],
      language: [],
      notes: [],
      provenance: [],
      publisher: [],
      relation: [],
      rights: [],
      source: [],
      bibnumber: []
    }
  end

  # @return [Hash]
  def structural_metadata
    {
      viewing_hint: [],
      viewing_direction: []
    }
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
    source = []
    source.map do |_source|
      {
        filename: '', # original filename
        label: '',
        annotations: [], # table_of_contents
        transcription: '', # fulltext
        checksum: '', # TODO: existing or computed? should we fixity check at migration?
        path: '' # "path to file in the bucket, won't actually be a path just a filename"
      }
    end
  end

  def unarranged_assets
    [] # just an array of filenames
  end
end
