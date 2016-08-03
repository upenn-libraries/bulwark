require 'sanitize'

class Repo < ActiveRecord::Base

  has_one :metadata_builder, dependent: :destroy, :validate => false
  has_one :version_control_agent, dependent: :destroy, :validate => false

  around_create :set_version_control_agent_and_repo

  validates :human_readable_name, presence: true
  validates :metadata_subdirectory, presence: true
  validates :assets_subdirectory, presence: true
  validates :file_extensions, presence: true
  validates :preservation_filename, presence: true

  validates :human_readable_name, multiple: false
  validates :directory, multiple: false

  serialize :metadata_sources, Array
  serialize :metadata_builder_id, Array
  serialize :ingested, Array
  serialize :review_status, Array
  serialize :steps, Hash

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
    self[:owner] = User.current
    mint_ezid
    self[:derivatives_subdirectory] = "#{Utils.config.object_derivatives_path}"
    self[:admin_subdirectory] = "#{Utils.config.object_admin_path}"
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
    self[:preservation_filename] = preservation_filename.concat(".xml") unless preservation_filename.ends_with?(".xml")
  end

  def review_status=(review_status)
    self[:review_status].push(Sanitize.fragment(review_status, Sanitize::Config::RESTRICTED)) if review_status.present?
  end

  def human_readable_name
    read_attribute(:human_readable_name) || ''
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

  def steps
    read_attribute(:steps) || ''
  end

  def create_remote
    # Function weirdness forcing update_steps to the top
    self.update_steps(:git_remote_initialized)
    unless Dir.exists?("#{assets_path_prefix}/#{self.directory}")
      self.version_control_agent.init_bare
      self.version_control_agent.clone
      _build_and_populate_directories(self.version_control_agent.working_path)
      self.version_control_agent.commit_bare("Added subdirectories according to the configuration specified in the repo configuration")
      self.version_control_agent.push_bare
      self.version_control_agent.delete_clone
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
      self.package_metadata_info
      self.update_steps(:published_preview)
      return @status
    rescue
      raise $!, "Ingest and index failed due to the following error(s): #{$!}", $!.backtrace
    end
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

  def directory_link
    url = "#{Rails.application.routes.url_helpers.rails_admin_url(:only_path => true)}/repo/#{self.id}/git_actions"
    return "<a href=\"#{url}\">#{self.directory}</a>"
  end

  def package_metadata_info
    File.open("#{self.version_control_agent.working_path}/#{self.admin_subdirectory}/#{self.directory.gsub(/\.git$/, '')}", "w+") do |f|
      self.metadata_builder.metadata_source.each do |source|
        f.puts "Source information for #{source.path}\npath: #{source.path}\nid (use to correlate children): #{source.id}\nsource_type: #{source.source_type}\nview_type: #{source.view_type}\nnum_objects: #{source.num_objects}\nx_start: #{source.x_start}\nx_stop: #{source.x_stop}\ny_start: #{source.y_start}\ny_stop: #{source.y_stop}\nchildren: #{source.children}\n\n"
      end
    end
    self.version_control_agent.commit("Added packaging info about metadata sources to admin directory")
    self.version_control_agent.push
  end

  def update_steps(task)
    self.steps[task] = true
    self.save!
  end

  def mint_ezid
    _mint_and_format_ezid
  end

  def self.repo_owners
    return User.where(guest: false).pluck(:email, :email)
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
    Dir.mkdir("#{assets_subdirectory}") && FileUtils.touch("#{assets_subdirectory}/.keep") unless File.exists?(assets_subdirectory)
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

  def _initialize_steps
    self.steps = {
      :git_remote_initialized => false,
      :metadata_sources_selected => false,
      :metadata_source_type_specified => false,
      :metadata_source_additional_info_set => false,
      :metadata_extracted => false,
      :metadata_mappings_generated => false,
      :preservation_xml_generated => false,
      :published_preview => false
    }
  end

  def _set_version_control_agent
    self.version_control_agent = VersionControlAgent.new(:vc_type => "GitAnnex")
    self.version_control_agent.save!
  end

  def _set_metadata_builder
    self.metadata_builder = MetadataBuilder.new(:parent_repo => self.id)
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

  def _mint_and_format_ezid
    #TODO: Replace with test EZID minting when in place:
    minted_id = SecureRandom.hex(10)
    while Repo.where(directory: "#{Utils.config.repository_prefix}_#{self.human_readable_name}_#{minted_id}.git").pluck(:directory).present?
      minted_id = SecureRandom.hex(10)
    end
    
    self[:unique_identifier] = "#{Utils.config.repository_prefix}_#{minted_id}"
    self[:directory] = "#{Utils.config.repository_prefix}_#{self.human_readable_name}_#{minted_id}"
    _concatenate_git
  end

  # TODO: Determine if this is really the best place to put this because we're dealing with Git bare repo best practices
  def _concatenate_git
    self.directory.concat('.git') unless self.directory =~ /.git$/ || self.directory.nil?
  end


end
