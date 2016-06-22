require 'sanitize'

class Repo < ActiveRecord::Base

  has_one :metadata_builder, dependent: :destroy, :validate => false
  has_one :version_control_agent, dependent: :destroy, :validate => false

  before_validation :_concatenate_git

  around_create :set_version_control_agent_and_repo

  validates :title, presence: true
  validates :directory, presence: true
  validates :preservation_filename, presence: true

  validates :title, multiple: false
  validates :directory, multiple: false

  validate :subdirectories

  serialize :metadata_sources, Array
  serialize :metadata_builder_id, Array
  serialize :ingested, Array
  serialize :review_status, Array

  include Filesystem
  include FileExtensions

  def set_version_control_agent_and_repo
    yield
    set_defaults
    _set_version_control_agent
    create_remote
    _set_metadata_builder
  end

  def set_defaults
    self[:derivatives_subdirectory] = "#{Utils.config.object_derivatives_path}"
  end

  def metadata_subdirectory=(metadata_subdirectory)
    self[:metadata_subdirectory] = "#{Utils.config.object_data_path}/#{metadata_subdirectory}"
  end

  def assets_subdirectory=(assets_subdirectory)
    self[:assets_subdirectory] = "#{Utils.config.object_data_path}/#{assets_subdirectory}"
  end

  def file_extensions=(file_extensions)
    self[:file_extensions] = file_extensions.reject(&:empty?).join(",")
  end

  def nested_relationships=(nested_relationships)
    nested_relationships.reject!(&:empty?)
    self[:nested_relationships] = nested_relationships
  end

  def preservation_filename=(preservation_filename)
    self[:preservation_filename] = preservation_filename.present? ? (preservation_filename.concat(".xml") unless preservation_filename.ends_with?(".xml")) : nil
  end

  def review_status=(review_status)
    self[:review_status].push(Sanitize.fragment(review_status, Sanitize::Config::RESTRICTED)) if review_status.present?
  end

  def title
    read_attribute(:title) || ''
  end

  def directory
    read_attribute(:directory) || ''
  end

  def description
    read_attribute(:description) || ''
  end

  def metadata_subdirectory
    read_attribute(:metadata_subdirectory) || ''
  end

  def assets_subdirectory
    read_attribute(:assets_subdirectory) || ''
  end

  def file_extensions
    read_attribute(:file_extensions) || ''
  end

  def ingested
    read_attribute(:ingested) || ''
  end

  def metadata_source_extensions
    read_attribute(:metadata_source_extensions) || ''
  end

  def review_status
    read_attribute(:review_status) || ''
  end


  def create_remote
    unless Dir.exists?("#{assets_path_prefix}/#{self.directory}")
      self.version_control_agent.init_bare
      self.version_control_agent.clone
      _build_and_populate_directories(self.version_control_agent.working_path)
      self.version_control_agent.commit_bare("Added subdirectories according to the configuration specified in the repo configuration")
      self.version_control_agent.push_bare
      self.version_control_agent.delete_clone
      return { :success => "Remote successfully created" }
    else
      return { :error => "Remote already exists" }
    end
  end

  def ingest(directory)
    begin
      ingest_array = Array.new
      Dir.glob("#{directory}/*").each do |file|
        @status = Utils::Process.import(file, self)
        ingest_array << File.basename(file, File.extname(file))
      end
      self.ingested = ingest_array
      _refresh_assets
      self.save!
      return @status
    rescue
      raise $!, "Ingest and index failed due to the following error(s): #{$!}", $!.backtrace
    end
  end

  def reindex
    ActiveFedora::Base.reindex_everything
  end

  def load_file_extensions
    return asset_file_extensions
  end

  def load_metadata_source_extensions
    return metadata_source_file_extensions
  end

  def preserve_exists?
    return _check_if_preserve_exists
  end

  def update_object_review_status
    _update_object_review_status
  end

  def subdirectories
    _subdirectories
  end

private

  def _build_and_populate_directories(working_copy_path)
    admin_directory = "#{Utils.config.object_admin_path}"
    data_directory = "#{Utils.config.object_data_path}"
    metadata_subdirectory = "#{self.metadata_subdirectory}"
    assets_subdirectory = "#{self.assets_subdirectory}"
    derivatives_subdirectory = "#{self.derivatives_subdirectory}"
    Dir.chdir("#{working_copy_path}")
    Dir.mkdir("#{admin_directory}")
    Dir.mkdir("#{data_directory}")
    Dir.mkdir("#{metadata_subdirectory}") && FileUtils.touch("#{metadata_subdirectory}/.keep")
    Dir.mkdir("#{assets_subdirectory}") && FileUtils.touch("#{assets_subdirectory}/.keep")
    Dir.mkdir("#{derivatives_subdirectory}") && FileUtils.touch("#{derivatives_subdirectory}/.keep")
    _populate_admin_manifest("#{admin_directory}")
  end

  def _populate_admin_manifest(admin_path)
    filesystem_semantics_path = "#{admin_path}/#{Utils.config.object_semantics_location}"
    file_types = _define_file_types
    metadata_line = "#{Utils.config.metadata_path_label}: #{self.metadata_subdirectory}/#{self.metadata_source_extensions}"
    assets_line = "#{Utils.config.file_path_label}: #{self.assets_subdirectory}/#{file_types}"
    File.open(filesystem_semantics_path, "w+") do |file|
      file.puts("#{metadata_line}\n#{assets_line}")
    end
  end

  def _define_file_types
    ft = self.file_extensions.split(",")
    ft.map! { |f| ".#{f}"}
    aft = ft.join(',')
    aft = "*{#{aft}}"
    return aft
  end

  def _set_version_control_agent
    self.version_control_agent = VersionControlAgent.new(:vc_type => "GitAnnex")
    self.version_control_agent.save!
  end

  def _set_metadata_builder
    self.metadata_builder = MetadataBuilder.new
    self.metadata_builder.repo = self
    self.metadata_builder.save!
    self.save!
  end

  def _refresh_assets
    display_path = "#{Utils.config.assets_display_path}/#{self.directory}"
    if File.directory?("#{Utils.config.assets_display_path}/#{self.directory}")
      Dir.chdir(display_path)
      self.version_control_agent.sync_content
    else
      self.version_control_agent.clone(:destination => display_path)
      _refresh_assets
    end
  end

  def _check_if_preserve_exists
    self.version_control_agent.clone
    self.metadata_builder.preserve.each {|f| @fname = f if File.basename(f) == self.preservation_filename}
    self.version_control_agent.get(:get_location => @fname)
    exist_status = File.exists?(@fname)
    self.version_control_agent.drop
    self.version_control_agent.delete_clone
    return exist_status
  end

  def _subdirectories
    errors.add(:metadata_subdirectory, "Metadata subdirectory cannot be blank") if self.metadata_subdirectory == "data/"
    errors.add(:assets_subdirectory, "Assets subdirectory cannot be blank") if self.assets_subdirectory == "data/"
  end

  # TODO: Determine if this is really the best place to put this because we're dealing with Git bare repo best practices
  def _concatenate_git
    self.directory.concat('.git') unless self.directory =~ /.git$/ || self.directory.nil?
  end


end
