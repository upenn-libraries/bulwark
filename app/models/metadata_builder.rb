class MetadataBuilder < ActiveRecord::Base

  belongs_to :repo, :foreign_key => "repo_id"

  has_many :metadata_source, dependent: :destroy, :validate => false

  include Utils

  validates :parent_repo, presence: true

  serialize :preserve, Set

  @@xml_tags = Array.new
  @@error_message = nil

  def parent_repo=(parent_repo)
    self[:parent_repo] = parent_repo
    @repo = Repo.find(parent_repo)
    self.repo = @repo
  end

  def preserve
    read_attribute(:preserve) || ''
  end

  def parent_repo
    read_attribute(:parent_repo) || ''
  end

  def available_metadata_files
    available_metadata_files = Array.new
    self.repo.version_control_agent.clone
    Dir.glob("#{self.repo.version_control_agent.working_path}/#{self.repo.metadata_subdirectory}/*.#{self.repo.metadata_source_extensions}") do |file|
      available_metadata_files << file
    end
    self.repo.version_control_agent.delete_clone
    return available_metadata_files
  end

  def unidentified_files
    identified = (self.source + self.preserve).uniq!
    unidentified = self.available_metadata_files - identified
    return unidentified
  end

  def set_source(source_files)
    #TODO: Consider removing from MetadataBuilder
    self.source = source_files
    self.save!

    self.metadata_source.each do |mb_source|
      mb_source.delete unless source_files.include?(mb_source.path)
    end
    source_files.each do |source|
      self.metadata_source << MetadataSource.create(:path => source) unless MetadataSource.where(:path => source).pluck(:path).present?
    end
    self.save!
  end

  def clear_unidentified_files
    unidentified_files = self.unidentified_files
    self.repo.version_control_agent.clone
    unidentified_files.each do |f|
      self.repo.version_control_agent.unlock(f)
      self.repo.version_control_agent.drop(:drop_location => f) && `rm -rf #{f}`
    end
    self.repo.version_control_agent.commit("Removed files not identified as metadata source and/or for long-term preservation: #{unidentified_files}")
    self.repo.version_control_agent.push
    self.repo.version_control_agent.delete_clone
  end

  def transform_and_ingest(array)
    @vca = self.repo.version_control_agent
    array.each do |p|
      key, val = p
      @vca.clone
      @vca.get(:get_location => val)
      @vca.unlock(val)
      transformed_repo_path = "#{Utils.config.transformed_dir}/#{@vca.remote_path.gsub("/","_")}"
      Dir.mkdir(transformed_repo_path) && Dir.chdir(transformed_repo_path)
      `xsltproc #{Rails.root}/lib/tasks/sv.xslt #{val}`
      @status = self.repo.ingest(transformed_repo_path)
      @vca.reset_hard
      @vca.delete_clone
      FileUtils.rm_rf(transformed_repo_path, :secure => true) if File.directory?(transformed_repo_path)
    end
    return @status
  end

end
