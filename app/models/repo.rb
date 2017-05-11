require 'sanitize'

class Repo < ActiveRecord::Base

  include ModelNamingExtensions::Naming
  include Utils::Artifacts::ProblemsLog

  has_one :metadata_builder, dependent: :destroy, :validate => false
  has_one :version_control_agent, dependent: :destroy, :validate => false

  has_many :endpoint, dependent: :destroy
  validates_associated :endpoint

  around_create :set_version_control_agent_and_repo

  validates :human_readable_name, presence: true
  validates :metadata_subdirectory, presence: true
  validates :assets_subdirectory, presence: true
  validates :file_extensions, presence: true
  validates :metadata_source_extensions, presence: true
  validates :preservation_filename, presence: true

  serialize :file_extensions, Array
  serialize :metadata_source_extensions, Array
  serialize :metadata_sources, Array
  serialize :metadata_builder_id, Array
  serialize :review_status, Array
  serialize :steps, Hash
  serialize :problem_files, Hash
  serialize :file_display_attributes, Hash
  serialize :images_to_render, Hash
  serialize :last_action_performed, Hash

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
    self[:derivatives_subdirectory] = "#{Utils.config[:object_derivatives_path]}"
    self[:admin_subdirectory] = "#{Utils.config[:object_admin_path]}"
    self[:ingested] = false
  end

  def metadata_subdirectory=(metadata_subdirectory)
    self[:metadata_subdirectory] = "#{Utils.config[:object_data_path]}/#{metadata_subdirectory}"
  end

  def assets_subdirectory=(assets_subdirectory)
    self[:assets_subdirectory] = "#{Utils.config[:object_data_path]}/#{assets_subdirectory}"
  end


  def file_extensions=(file_extensions)
    self[:file_extensions] = Array.wrap(file_extensions).reject(&:blank?)
  end

  def metadata_source_extensions=(metadata_source_extensions)
    self[:metadata_source_extensions] = Array.wrap(metadata_source_extensions).reject(&:blank?)
  end

  def nested_relationships=(nested_relationships)
    self[:nested_relationships] = nested_relationships.reject(&:blank?)
  end

  def preservation_filename=(preservation_filename)
    self[:preservation_filename] = preservation_filename.xmlify
  end

  def thumbnail=(thumbnail)
    self[:thumbnail] = thumbnail
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

  def thumbnail
    read_attribute(:thumbnail) || ''
  end

  def create_remote
    # Function weirdness forcing update_steps to the top
    self.update_steps(:git_remote_initialized)
    unless Dir.exists?("#{Utils.config[:assets_path]}/#{self.names.directory}")
      self.version_control_agent.init_bare
      working_path = self.version_control_agent.clone
      directory_sets = _build_and_populate_directories(working_path)
      directory_sets.each{|dir_set| dir_set.each{|add_type,dirs| dirs.each{|dir| self.version_control_agent.add({:content => dir, :add_type => add_type}, working_path) } } }
      self.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.commit_bare'), working_path)
      self.version_control_agent.push(working_path)
      self.version_control_agent.delete_clone(working_path)
      self.version_control_agent.set_remote_permissions
    end
    self.update_last_action(action_description[:git_remote_initialized])
  end

  def ingest(file, working_path)
    begin
      @status = Utils::Process.import(file, self, working_path)
      self.thumbnail = default_thumbnail
      self.save!
      Utils::Process.generate_thumbnail(self) if self.thumbnail.present?
      self.package_metadata_info(working_path)
      self.generate_logs(working_path)
      self.version_control_agent.add({:content => "#{working_path}/#{self.derivatives_subdirectory}"}, working_path)
      self.version_control_agent.add({:content => "#{working_path}/#{self.admin_subdirectory}"}, working_path)
      self.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.generated_all_derivatives'), working_path)
      self.version_control_agent.push(working_path)
      self.metadata_builder.last_file_checks = DateTime.now
      self.metadata_builder.save!
    rescue => exception
       self.save!
       raise $!, I18n.t('colenda.errors.repos.ingest_error', :backtrace => exception.message)
    end
  end

  def lock_keep_files(working_path)
    if File.exist?(working_path)
      self.version_control_agent.lock("#{self.metadata_subdirectory}/.keep")
      self.version_control_agent.lock("#{self.assets_subdirectory}/.keep")
      self.version_control_agent.lock("#{self.derivatives_subdirectory}/.keep")
    end
  end

  def package_metadata_info(working_path)
    self.version_control_agent.unlock({:content => self.admin_subdirectory}, working_path)
    File.open("#{working_path}/#{self.admin_subdirectory}/#{self.names.directory}", 'w+') do |f|
      self.metadata_builder.metadata_source.each do |source|
        f.puts I18n.t('colenda.version_control_agents.packaging_info', :source_path => source.path, :source_id => source.id, :source_type => source.source_type, :source_view_type => source.view_type, :source_num_objects => source.num_objects, :source_x_start => source.x_start, :source_x_stop => source.x_stop, :source_y_start => source.y_start, :source_y_stop => source.y_stop, :source_children => source.children)
      end
    end
  end

  def generate_logs(destination_path)
    begin
      temp_location = self.problems_log
      destination = "#{destination_path}/#{Utils.config[:object_admin_path]}/#{Utils.config[:problem_log]}"
      FileUtils.mv(temp_location, destination)
    rescue => exception
      return unless self.problem_files.present?
      raise Utils::Error::Artifacts.new(error_message(exception.message))
    end

  end

  def update_last_action(update_string)
    self.last_action_performed = { :description => update_string }
    self.save!
  end

  def push_artifacts(working_path)
    begin
      self.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.post_ingest_artifacts'), working_path)
      self.version_control_agent.push(working_path)
    rescue
      self.version_control_agent.push(working_path)
    end
  end

  #TODO: Eventually offload to metadata source subclasses
  def default_thumbnail
    structural_types = %w[structural_bibid custom bibliophilly_structural]
    single_structural_source = MetadataSource.where('metadata_builder_id = ? AND source_type IN (?)', self.metadata_builder, structural_types).pluck(:id)
    single_structural_source.length == 1 ? MetadataSource.find(single_structural_source.first).thumbnail : nil
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
    "<a href=\"#{url}\">#{self.names.directory}</a>"
  end

  def update_steps(task)
    self.steps[task] = true
    self.save!
  end

  def log_problem_file(file, problem)
    self.problem_files[file] = problem
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
    readme = _generate_readme(working_path)
    _make_subdir(admin_directory)
    _make_subdir(data_directory)
    _make_subdir(metadata_subdirectory, :keep => true)
    _make_subdir(assets_subdirectory, :keep => true)
    _make_subdir(derivatives_subdirectory, :keep => true)
    _populate_admin_manifest("#{admin_directory}")
    init_script_directory = _add_init_scripts(admin_directory)
    [{:store => [admin_directory, derivatives_subdirectory, readme], :git => [init_script_directory, data_directory, metadata_subdirectory, assets_subdirectory]}]
  end

  def _make_subdir(directory, options = {})
    FileUtils.mkdir_p(directory)
    FileUtils.touch("#{directory}/.keep") if options[:keep]
  end

  def _add_init_scripts(directory)
    FileUtils.mkdir_p("#{directory}/bin")
    FileUtils.cp(Utils.config[:init_script_path], "#{directory}/bin/init.sh")
    FileUtils.chmod(Utils.config[:init_script_permissions], "#{directory}/bin/init.sh")
    "#{directory}/bin/init.sh"
  end

  def _generate_readme(directory)
    readme_filename = 'README.md'
    File.open(readme_filename, 'w') { |file| file.write(I18n.t('colenda.version_control_agents.readme_contents', :unique_identifier => self.unique_identifier)) }
    return "#{directory}/#{readme_filename}"
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
    self.version_control_agent.get({:location => fname}, working_path)
    exist_status = File.exists?(fname)
    self.version_control_agent.drop(working_path)
    self.version_control_agent.delete_clone(working_path)
    exist_status
  end

  def action_description
    { :git_remote_initialized => 'Repo initialized' }
  end

  def mint_initial_ark
    Ezid::Identifier.mint
  end

end


