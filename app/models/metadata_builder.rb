class MetadataBuilder < ActiveRecord::Base

  include Utils

  validates :parent_repo, presence: true
  validates :source, presence: true

  serialize :source

  before_validation :set_source

  def set_source
    repo = Repo.find(self.parent_repo)
    repo.set_metadata_sources
    self.source = repo.metadata_sources
  end

end
