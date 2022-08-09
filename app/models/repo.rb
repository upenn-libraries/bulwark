require "net/http"
require 'sanitize'

class Repo < ActiveRecord::Base
  include DigitalObject::Gitannexable
  include DigitalObject::Derivatives
  include DigitalObject::Metadata
  include DigitalObject::Assets

  scope :new_format, -> { where(new_format: true) }
  scope :old_format, -> { where(new_format: false) }
  scope :name_search, ->(query) { where_like(:human_readable_name, query) }
  scope :id_search, ->(query) { where_like(:unique_identifier, query) }

  include ModelNamingExtensions::Naming

  has_one :metadata_builder, dependent: :destroy, :validate => false
  has_one :version_control_agent, dependent: :destroy, :validate => false

  has_many :endpoint, dependent: :destroy
  has_many :assets, dependent: :destroy
  has_many :digital_object_imports, dependent: :nullify
  validates_associated :endpoint

  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'

  around_create :set_version_control_agent_and_repo # this is essentially an after_create

  validates :human_readable_name, presence: true
  validates :metadata_subdirectory, presence: true
  validates :assets_subdirectory, presence: true
  validates :file_extensions, presence: true
  validates :metadata_source_extensions, presence: true
  validates :preservation_filename, presence: true

  validates_format_of :unique_identifier, :with => /ark:\/[a-zA-Z0-9]{5,}\/[a-zA-Z0-9]{5,}/, :allow_blank => true

  validates_uniqueness_of :unique_identifier, :allow_blank => true

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

  # kamanari config
  paginates_per 25
  max_paginates_per 200

  def set_version_control_agent_and_repo
    yield
    set_defaults
    _set_version_control_agent
    create_remote
    _set_metadata_builder
  end

  def set_defaults
    self[:unique_identifier] = mint_ezid unless self[:unique_identifier].present?
    self[:unique_identifier].strip!
    self[:derivatives_subdirectory] = Settings.digital_object.default_paths.derivatives_directory
    self[:admin_subdirectory] = Settings.digital_object.default_paths.admin_directory
    self[:ingested] = false
  end

  def metadata_subdirectory=(metadata_subdirectory)
    self[:metadata_subdirectory] = File.join(Settings.digital_object.default_paths.data_directory, metadata_subdirectory)
  end

  def assets_subdirectory=(assets_subdirectory)
    self[:assets_subdirectory] = File.join(Settings.digital_object.default_paths.data_directory, assets_subdirectory)
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

  # Creates remote, clones repository, adds content that all repositories are expected to have.
  def create_remote
    # Function weirdness forcing update_steps to the top
    self.update_steps(:git_remote_initialized)
    unless Dir.exists?(File.join(Settings.digital_object.remotes_path, self.names.directory))
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

  def update_last_action(update_string)
    self.last_action_performed = { :description => update_string }
    self.save!
  end

  def update_steps(task)
    self.steps[task] = true
    self.save!
  end

  def mint_ezid
    mint_initial_ark
  end

  # Could be put into a concern for other models to be searched
  # @param [Symbol] column_name
  # @param [String] query
  def self.where_like(column_name, query)
    column = self.arel_table[column_name]
    where(column.matches("%#{sanitize_sql_like(query)}%"))
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

  # Returning MetadataSource that contains structural metadata.
  def structural_metadata
    metadata_builder.metadata_source.find_by(source_type: MetadataSource::STRUCTURAL_TYPES)
  end

  # Returning MetadataSource that contains descriptive metadata.
  def descriptive_metadata
    metadata_builder.metadata_source.find_by(source_type: MetadataSource::DESCRIPTIVE_TYPES)
  end

  # Return true if the repo has at least one image as an asset.
  def has_images?
    images_to_render.present? || assets.where(mime_type: ['image/jpeg', 'image/tiff']).count.positive?
  end

  def bibid
    return nil unless descriptive_metadata
    descriptive_metadata.original_mappings["bibid"] || descriptive_metadata.original_mappings.fetch("bibnumber", []).first
  end

  # Deprecating the use of thumbnail_location for repos in the new format. In the new format, we
  # can calculate the thumbnail_location from data stored in the asset records.
  def thumbnail_location
    if new_format
      return nil if thumbnail.blank?
      location = assets.find_by!(filename: thumbnail)&.thumbnail_file_location
      location ? File.join(names.bucket, location) : nil
    else
      self[:thumbnail_location]
    end
  end

  def create_iiif_manifest
    return if assets.where(mime_type: ['image/jpeg', 'image/tiff']).count.zero?

    sequence = structural_metadata.user_defined_mappings['sequence'].map do |info|
      asset = assets.find_by(filename: info['filename'])
      {
        file: names.bucket + '%2F' + asset.access_file_location,
        label: info.fetch('label', nil),
        table_of_contents: info.fetch('table_of_contents', []).map { |t| { text: t } },
        additional_downloads: [
          {
            link: asset.original_file_link,
            label: "Original File",
            size: asset.size,
            format: asset.mime_type
          }
        ]
      }.delete_if { |_,v| v.blank? }
    end

    payload = {
      id: names.fedora,
      title: descriptive_metadata.user_defined_mappings['title'].join('; '),
      viewing_direction: structural_metadata.viewing_direction,
      viewing_hint: structural_metadata.viewing_hint,
      image_server: Settings.iiif.image_server,
      sequence: sequence
    }.to_json

    MarmiteClient.iiif_presentation(names.fedora, payload)
  end

  def thumbnail_link
    return '' unless thumbnail_location

    Addressable::URI.new(
      path: thumbnail_location,
      host: Settings.digital_object.special_remote.host,
      scheme: Settings.digital_object.special_remote.protocol.gsub('://', '')
    ).to_s
  end

  # Validates that all the filenames referenced in the structural metadata are valid.
  def validate_structural_metadata!
    valid_filenames = assets.pluck(:filename)
    filenames = structural_metadata.filenames
    invalid_filenames = filenames - valid_filenames
    return unless invalid_filenames.present?
    raise "Structural metadata contains the following invalid filenames: #{invalid_filenames.join(', ')}"
  end

  def solr_document
    document = {
      'id' => names.fedora,
      'active_fedora_model_ssi' => 'Manuscript', # TODO: Can remove once Blacklight doesn't depend on these fields
      'has_model_ssim' => ['Manuscript'],
      'unique_identifier_tesim' => unique_identifier,
      'system_create_dtsi' => first_published_at.utc.iso8601,
      'system_modified_dtsi' => last_published_at.utc.iso8601,
      'thumbnail_location_ssi' => thumbnail_location,
      'bibnumber_ssi' => bibid
    }

    MetadataSource::VALID_DESCRIPTIVE_METADATA_FIELDS.each do |field|
      values = descriptive_metadata.user_defined_mappings.fetch(field, [])
      next if values.blank?

      document["#{field}_tesim"] = values
      document["#{field}_ssim"] = values
      document["#{field}_sim"] = values
    end

    document
  end

  # @return [True] if publish was successful
  # @return [False] if publish was not successful
  def publish
    # TODO: check that iiif manifest is available?
    # TODO: check that descriptive metadata and structural metadata are present?

    # Rollback first_published_at and last_published_at, if solr requests are not successful.
    self.transaction do
      now = Time.current
      self.first_published_at = now if first_published_at.blank?
      self.last_published_at = now
      self.published = true
      save!
      # Add Solr Document to Solr Core -- raise error if cannot be added to Solr Core
      solr = RSolr.connect(url: Settings.solr.url)
      solr.add(self.solr_document)
      solr.commit
    end

    true
  rescue => e
    Honeybadger.notify(e)
    false
  end

  def unpublish
    return false unless published

    self.transaction do
      self.published = false
      save!
      solr = RSolr.connect(url: Settings.solr.url)
      solr.delete_by_query "id:#{names.fedora}"
      solr.commit
    end
    true
  rescue => e
    Honeybadger.notify(e)
    false
  end

  def to_hash(structural: false)
    hash = {
      'id' => id,
      'unique_identifier' => unique_identifier,
      'directive_name' => human_readable_name,
      'created_at' => created_at&.to_s(:display),
      'created_by' => created_by&.email,
      'updated_at' => updated_at&.to_s(:display),
      'updated_by' => updated_by&.email,
      'published' => published,
      'first_published_at' => first_published_at&.to_s(:display),
      'last_published_at' => last_published_at&.to_s(:display),
      'number_of_assets' => assets.count,
      'metadata' => descriptive_metadata.original_mappings
    }

    if structural
      sequence = structural_metadata.user_defined_mappings['sequence'].map do |h|
        h.delete('sequence')
        h
      end

      hash['structural'] = { 'sequence' => sequence }
    end

    hash
  end

  private

  def _build_and_populate_directories(working_path)
    admin_directory = File.join(working_path, Settings.digital_object.default_paths.admin_directory)
    data_directory = File.join(working_path, Settings.digital_object.default_paths.data_directory)
    metadata_subdirectory = File.join(working_path, self.metadata_subdirectory)
    assets_subdirectory = File.join(working_path, self.assets_subdirectory)
    derivatives_subdirectory = File.join(working_path, self.derivatives_subdirectory)
    readme = _generate_readme(working_path)
    _make_subdir(admin_directory)
    _make_subdir(data_directory)
    _make_subdir(metadata_subdirectory, keep: true)
    _make_subdir(assets_subdirectory, keep: true)
    _make_subdir(derivatives_subdirectory, keep: true)
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
    FileUtils.cp(Rails.root.join('docker', 'init.sh'), "#{directory}/bin/init.sh")
    FileUtils.chmod('a+x', "#{directory}/bin/init.sh")
    "#{directory}/bin/init.sh"
  end

  def _generate_readme(directory)
    readme_filename = File.join(directory, 'README.md')
    File.open(readme_filename, 'w') do |file|
      file.write(I18n.t('colenda.version_control_agents.readme_contents', unique_identifier: self.unique_identifier))
    end
    readme_filename
  end

  def _populate_admin_manifest(admin_path)
    filesystem_semantics_path = "#{admin_path}/#{Settings.digital_object.default_paths.semantics_filename}"
    file_types = format_types(self.file_extensions)
    metadata_source_types = format_types(self.metadata_source_extensions)
    metadata_line = "METADATA_PATH: #{self.metadata_subdirectory}/#{metadata_source_types}"
    assets_line = "ASSETS_PATH: #{self.assets_subdirectory}/#{file_types}"
    File.open(filesystem_semantics_path, "w+") do |file|
      file.puts("#{metadata_line}\n#{assets_line}")
    end

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

  def action_description
    { :git_remote_initialized => 'Repo initialized' }
  end

  def mint_initial_ark
    Ezid::Identifier.mint
  end
end
