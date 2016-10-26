require 'sanitize'

class Repo < ActiveRecord::Base

  include ModelNamingExtensions::Naming

  has_one :metadata_builder, dependent: :destroy, :validate => false
  has_one :version_control_agent, dependent: :destroy, :validate => false

  around_create :set_version_control_agent_and_repo

  validates :human_readable_name, presence: true
  validates :metadata_subdirectory, presence: true
  validates :assets_subdirectory, presence: true
  validates :file_extensions, presence: true
  validates :preservation_filename, presence: true

  validates :directory, multiple: false

  serialize :file_extensions, Array
  serialize :metadata_source_extensions, Array
  serialize :metadata_sources, Array
  serialize :metadata_builder_id, Array
  serialize :ingested, Array
  serialize :review_status, Array
  serialize :steps, Hash
  serialize :problem_files, Hash
  serialize :images_to_render, Hash

  def set_version_control_agent_and_repo
    yield
    set_defaults
    _set_version_control_agent
    create_remote
    _set_metadata_builder
  end

  def set_defaults
    self[:owner] = User.current
    self[:unique_identifier] = mint_ezid
    self[:directory] = self.names.directory
    self[:derivatives_subdirectory] = "#{Utils.config[:object_derivatives_path]}"
    self[:admin_subdirectory] = "#{Utils.config[:object_admin_path]}"
    self[:has_thumbnail] = false
  end

  def metadata_subdirectory=(metadata_subdirectory)
    self[:metadata_subdirectory] = "#{Utils.config[:object_data_path]}/#{metadata_subdirectory}"
  end

  def assets_subdirectory=(assets_subdirectory)
    self[:assets_subdirectory] = "#{Utils.config[:object_data_path]}/#{assets_subdirectory}"
  end


  def file_extensions=(file_extensions)
    self[:file_extensions] = Array.wrap(file_extensions).reject(&:empty?)
  end

  def metadata_source_extensions=(metadata_source_extensions)
    self[:metadata_source_extensions] = Array.wrap(metadata_source_extensions).reject(&:empty?)
  end

  def nested_relationships=(nested_relationships)
    self[:nested_relationships] = nested_relationships.reject(&:empty?)
  end

  def preservation_filename=(preservation_filename)
    self[:preservation_filename] = preservation_filename.xmlify
  end

  def review_status=(review_status)
    self[:review_status].push(Sanitize.fragment(review_status, Sanitize::Config::RESTRICTED)) if review_status.present?
  end

  def images_to_render=(images_to_render)
    self[:images_to_render] = images_to_render.present? ? images_to_render : {}
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

  def images_to_render
    read_attribute(:images_to_render) || ''
  end

  def has_thumbnail
    read_attribute(:has_thumbnail) || ''
  end
  alias_method :has_thumbnail?, :has_thumbnail

  def create_remote
    # Function weirdness forcing update_steps to the top
    self.update_steps(:git_remote_initialized)
    unless Dir.exists?("#{Utils.config[:assets_path]}/#{self.directory}")
      self.version_control_agent.init_bare
      working_path = self.version_control_agent.clone
      _build_and_populate_directories(working_path)
      self.version_control_agent.commit_bare(I18n.t('colenda.version_control_agents.commit_messages.commit_bare'))
      self.version_control_agent.push_bare
      self.version_control_agent.delete_clone
    end
  end

  def ingest(file, working_path)
    begin
      ingest_array = Array.new
      @status = Utils::Process.import(file, self, working_path)
      ingest_array << File.basename(file, File.extname(file))
      self.ingested = ingest_array
      Utils::Process.refresh_assets(self)
      self.save!
      self.package_metadata_info(working_path)
      self.update_steps(:published_preview)
      @status
    rescue
      raise $!, I18n.t('colenda.errors.repos.ingest_error', :backtrace => $!.backtrace)
    end
  end

  def load_file_extensions
    FileExtensions.asset_file_extensions
  end

  def load_metadata_source_extensions
    FileExtensions.metadata_source_file_extensions
  end

  def preserve_exists?
    _check_if_preserve_exists
  end

  def directory_link
    url = "#{Rails.application.routes.url_helpers.rails_admin_url(:only_path => true)}/repo/#{self.id}/git_actions"
    "<a href=\"#{url}\">#{self.directory}</a>"
  end

  def package_metadata_info(working_path)
    File.open("#{working_path}/#{self.admin_subdirectory}/#{self.directory.gsub(/\.git$/, '')}", 'w+') do |f|
      self.metadata_builder.metadata_source.each do |source|
        f.puts I18n.t('colenda.version_control_agents.packaging_info', :source_path => source.path, :source_id => source.id, :source_type => source.source_type, :source_view_type => source.view_type, :source_num_objects => source.num_objects, :source_x_start => source.x_start, :source_x_stop => source.x_stop, :source_y_start => source.y_start, :source_y_stop => source.y_stop, :source_children => source.children)
      end
    end
    self.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.package_metadata_info'))
    self.version_control_agent.push
  end

  def update_steps(task)
    self.steps[task] = true
    self.save!
  end

  def mint_ezid
    mint_initial_ark
  end

  #TODO: Add a field that indicates repo ownership candidacy
  def self.repo_owners
    User.where(guest: false).pluck(:email, :email)
  end

  def format_types(extensions_array)
    formatted_types = ''
    if extensions_array.length > 1
      ft = extensions_array.map { |f| ".#{f}"}
      file_extensions = ft.join(',')
      formatted_types = file_extensions.manifest_multiple
    else
      formatted_types = extensions_array.first.manifest_singular
    end
    formatted_types
  end

private

  def _build_and_populate_directories(working_path)
    admin_directory = "#{working_path}/#{Utils.config[:object_admin_path]}"
    data_directory = "#{working_path}/#{Utils.config[:object_data_path]}"
    metadata_subdirectory = "#{working_path}/#{self.metadata_subdirectory}"
    assets_subdirectory = "#{working_path}/#{self.assets_subdirectory}"
    derivatives_subdirectory = "#{working_path}/#{self.derivatives_subdirectory}"
    _make_and_keep(admin_directory)
    _make_and_keep(data_directory)
    _make_and_keep(metadata_subdirectory, :keep => true)
    _make_and_keep(assets_subdirectory, :keep => true)
    _make_and_keep(derivatives_subdirectory, :keep => true)
    _populate_admin_manifest("#{admin_directory}")
  end

  def _make_and_keep(directory, options = {})
    FileUtils.mkdir_p(directory)
    FileUtils.touch("#{directory}/.keep") if options[:keep]
  end

  def _populate_admin_manifest(admin_path)
    filesystem_semantics_path = "#{admin_path}/#{Utils.config[:object_semantics_location]}"
    file_types = format_types(self.file_extensions)
    metadata_source_types = format_types(self.metadata_source_extensions)
    metadata_line = "#{Utils.config[:metadata_path_label]}: #{self.metadata_subdirectory}/#{metadata_source_types}"
    assets_line = "#{Utils.config[:file_path_label]}: #{self.assets_subdirectory}/#{file_types}"
    File.open(filesystem_semantics_path, "w+") do |file|
      file.puts("#{metadata_line}\n#{assets_line}")
    end
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
    self.version_control_agent = VersionControlAgent.new(:vc_type => 'GitAnnex')
    self.version_control_agent.save!
  end

  def _set_metadata_builder
    self.metadata_builder = MetadataBuilder.new(:parent_repo => self.id)
    self.metadata_builder.save!
    self.save!
  end

  def _check_if_preserve_exists
    working_path = self.version_control_agent.clone
    fname = "#{working_path}/#{self.preservation_filename}"
    self.version_control_agent.get(:get_location => fname)
    exist_status = File.exists?(fname)
    self.version_control_agent.drop
    self.version_control_agent.delete_clone
    exist_status
  end

  def mint_initial_ark
    Ezid::Identifier.mint
  end

end
