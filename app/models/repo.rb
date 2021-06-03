require "net/http"
require 'sanitize'

class Repo < ActiveRecord::Base
  include Cloneable

  scope :new_format, -> { where(new_format: true) }
  scope :old_format, -> { where(new_format: false) }
  scope :name_search, ->(query) { where_like(:human_readable_name, query) }
  scope :id_search, ->(query) { where_like(:unique_identifier, query) }

  include ModelNamingExtensions::Naming
  include Utils::Artifacts::ProblemsLog

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

  # Creates remote, clones repository, adds content that all repositories are expected to have.
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

  def set_metadata_from_ark
    # TODO: may need to extend here eventually to account for combined_ark format data
    url = URI.parse("#{MetadataSchema.config[:pqc_ark][:structural_http_lookup]}/#{self.unique_identifier.tr(":/","+=")}/#{MetadataSchema.config[:pqc_ark][:structural_lookup_suffix]}")
    req = Net::HTTP.new(url.host, url.port)
    res = req.request_head(url.path)
    data = Nokogiri::XML(open(url.to_s))
    data.remove_namespaces!
    source_type = data.xpath('//record/bib_id').children.present? ? 'pqc_desc' : 'pqc_combined_desc'

    if res.code == '200'
      # TODO: may need to extend here eventually to account for combined_ark format data
      desc = MetadataSource.where(:metadata_builder => self.metadata_builder, :path => "#{MetadataSchema.config[:pqc_ark][:structural_http_lookup]}/#{self.unique_identifier.tr(":/","+=")}/#{MetadataSchema.config[:pqc_ark][:structural_lookup_suffix]}", :source_type => 'pqc_combined_desc').first_or_create
      desc.update_attributes( view_type: 'horizontal',
                              num_objects: 1,
                              x_start: 1,
                              y_start: 2,
                              x_stop: 34,
                              y_stop: 2,
                              root_element: 'record',
                              source_type: source_type,
                              original_mappings: {'bibid' => data.xpath('//record/bib_id').children.first.text},
                              z: 1 )

      _set_combined_metadata_ark(desc)
      desc.original_mappings = desc.user_defined_mappings

      # TODO: may need to extend here eventually to account for combined_ark format data
      struct = MetadataSource.where(:metadata_builder => self.metadata_builder, :path => "#{MetadataSchema.config[:pqc_ark][:structural_http_lookup]}/#{self.unique_identifier.tr(":/","+=")}/#{MetadataSchema.config[:pqc_ark][:structural_lookup_suffix]}", :source_type => 'pqc_combined_struct').first_or_create
      struct.update_attributes( view_type: 'horizontal',
                                num_objects: 1,
                                x_start: 1,
                                y_start: 1,
                                x_stop: 1,
                                y_stop: 1,
                                root_element: 'pages',
                                parent_element: 'page',
                                source_type: 'pqc_combined_struct',
                                file_field: 'file_name',
                                z: 1 )

      _set_combined_metadata_ark(struct)

      struct.original_mappings = struct.user_defined_mappings

      desc.children << struct
      struct.save!
      desc.save!
      desc.metadata_builder.repo.update_steps(:metadata_source_type_specified)
    else
      structural_mappings, bib_id = _set_structural_metadata_ark(self.unique_identifier)
      desc = MetadataSource.where(:metadata_builder => self.metadata_builder, :path => "#{MetadataSchema.config[:pap][:http_lookup]}/#{bib_id}/#{MetadataSchema.config[:pap][:http_lookup_suffix]}").first_or_create
      desc.update_attributes( view_type: 'horizontal',
                              num_objects: 1,
                              x_start: 1,
                              y_start: 2,
                              x_stop: 34,
                              y_stop: 2,
                              root_element: 'record',
                              source_type: 'pqc_desc',
                              z: 1 )

      _set_descriptive_metadata_ark(bib_id, desc)

      struct = MetadataSource.where(:metadata_builder => self.metadata_builder, :path => "#{MetadataSchema.config[:pqc_ark][:structural_http_lookup]}/#{self.unique_identifier.tr(":/","+=")}/#{MetadataSchema.config[:pqc_ark][:structural_lookup_suffix]}").first_or_create
      struct.update_attributes( view_type: 'horizontal',
                                num_objects: 1,
                                x_start: 1,
                                y_start: 1,
                                x_stop: 1,
                                y_stop: 1,
                                root_element: 'pages',
                                parent_element: 'page',
                                source_type: 'pqc_ark',
                                file_field: 'file_name',
                                z: 1 )
      struct.original_mappings = structural_mappings
      struct.user_defined_mappings = structural_mappings
      desc.children << struct
      struct.save!
      desc.save!
      self.metadata_builder.metadata_source << desc
    end
    self.metadata_builder.save!
  end

  def update_ark_struct_metadata
    structural_mappings, bib_id = _set_structural_metadata_ark(self.unique_identifier)
    struct = MetadataSource.where(:metadata_builder => self.metadata_builder, :path => "#{MetadataSchema.config[:pqc_ark][:structural_http_lookup]}/#{self.unique_identifier.tr(":/","+=")}/#{MetadataSchema.config[:pqc_ark][:structural_lookup_suffix]}").first_or_create
    struct.update_attributes( view_type: 'horizontal',
                              num_objects: 1,
                              x_start: 1,
                              y_start: 1,
                              x_stop: 1,
                              y_stop: 1,
                              root_element: 'pages',
                              parent_element: 'page',
                              source_type: 'pqc_ark',
                              file_field: 'file_name',
                              z: 1 )

    struct.original_mappings = structural_mappings
    struct.user_defined_mappings = structural_mappings
    struct.save!
    self.metadata_builder.save!
  end

  def ingest(file, working_path)
    begin
      @status = Utils::Process.import(file, self, working_path)
      self.thumbnail = default_thumbnail
      self.save!
      if self.thumbnail.present?
        thumbnail_path = "#{self.assets_subdirectory}/#{self.thumbnail}"
        self.version_control_agent.get({:location => "#{working_path}/#{thumbnail_path}"}, working_path)
        self.version_control_agent.unlock({:content => "#{working_path}/#{thumbnail_path}"}, working_path)
        self.version_control_agent.add({:content => "#{working_path}/#{thumbnail_path}"}, working_path) # Why is this necessary if the file is already present?
        self.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.generated_previews'), working_path) # Why is this necessary?
        Utils::Process.generate_thumbnail(self, working_path)
      end
      self.version_control_agent.lock(thumbnail_path, working_path)
      self.package_metadata_info(working_path)
      self.generate_logs(working_path)
      self.version_control_agent.add({:content => "#{working_path}/#{self.admin_subdirectory}"}, working_path)
      self.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.ingest_complete'), working_path)
      self.version_control_agent.lock(self.admin_subdirectory, working_path)
      self.version_control_agent.push({:content => "#{working_path}/#{self.admin_subdirectory}"}, working_path)
      self.metadata_builder.last_file_checks = DateTime.now
      self.metadata_builder.save!
    rescue => e
       self.save!
       raise # Raises last error
    end
  end

  def package_metadata_info(working_path)
    self.version_control_agent.get({:location => self.admin_subdirectory}, working_path)
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
      raise Utils::Error::Artifacts.new(exception.message)
    end

  end

  def update_last_action(update_string)
    self.last_action_performed = { :description => update_string }
    self.save!
  end

  # Not used
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
    structural_types = %w[structural_bibid custom kaplan_structural pap_structural pqc_ark pqc_combined_struct pqc_structural]
    single_structural_source = MetadataSource.where('metadata_builder_id = ? AND source_type IN (?)', self.metadata_builder, structural_types).pluck(:id)
    single_structural_source.length == 1 ? MetadataSource.find(single_structural_source.first).thumbnail : nil
  end

  def load_file_extensions
    FileExtensions.asset_file_extensions
  end

  def load_metadata_source_extensions
    FileExtensions.metadata_source_file_extensions
  end

  # Not Called.
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

  # Not used.
  def set_image_data
    self.images_to_render["iiif"]["images"] = {}
    working_directory = self.version_control_agent.clone
    ms = self.metadata_builder.metadata_source.find_all { |ms| ms.source_type == 'structural_bibid' }.first
    ms.user_defined_mappings.each do |mapping|
      sha_key = self.file_display_attributes.select{|k, v| v[:file_name].end_with?("#{mapping[1]["file_name"]}.jpeg")}.first[0]
      self.images_to_render["iiif"]["images"]["#{self.names.bucket}%2F#{sha_key}"] = {
          "page_number" => "#{mapping[1]["page_number"]}#{%w[recto verso].include?(mapping[1]["side"]) ? mapping[1]["side"][0] : nil}",
          "file_name" => mapping[1]["file_name"],
          "description" => mapping[1]["description"].present? ? mapping[1]["description"] : nil,
          "tocentry_data" => mapping[1]['tocentry']
      }
    end
    self.save!
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
        file: names.bucket + '/' + asset.access_file_location,
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
      image_server: Bulwark::Config.iiif[:image_server],
      sequence: sequence
    }.to_json

    MarmiteClient.iiif_presentation(names.fedora, payload)
  end

  def thumbnail_link
    return '' unless thumbnail_location

    Addressable::URI.new(
      path: thumbnail_location,
      host: Utils::Storage::Ceph.config.read_host,
      scheme: Utils::Storage::Ceph.config.read_protocol.gsub('://', '')
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
      'system_modified_dtsi' => last_published_at.utc.iso8601
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
      solr = RSolr.connect(url: Bulwark::Config.solr[:url])
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
      solr = RSolr.connect(url: Bulwark::Config.solr[:url])
      solr.delete_by_query "id:#{names.fedora}"
      solr.commit
    end
    true
  rescue => e
    Honeybadger.notify(e)
    false
  end

  private

  def _build_and_populate_directories(working_path)
    admin_directory = File.join(working_path, Utils.config[:object_admin_path])
    data_directory = File.join(working_path, Utils.config[:object_data_path])
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
    FileUtils.cp(Utils.config[:init_script_path], "#{directory}/bin/init.sh")
    FileUtils.chmod(Utils.config[:init_script_permissions], "#{directory}/bin/init.sh")
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

  # Not called.
  def _check_if_preserve_exists
    working_path = self.version_control_agent.clone
    fname = "#{working_path}/#{self.preservation_filename}"
    self.version_control_agent.get({:location => fname}, working_path)
    exist_status = File.exists?(fname)
    self.version_control_agent.drop(working_path)
    self.version_control_agent.delete_clone(working_path)
    exist_status
  end

  def _set_combined_metadata_ark(metadata_source)
    metadata_source.set_metadata_mappings
  end

  def _set_descriptive_metadata_ark(bib_id, metadata_source)
    url = "#{MetadataSchema.config[:pap][:http_lookup]}/#{bib_id}/#{MetadataSchema.config[:pap][:http_lookup_suffix]}"
    begin
      data = Nokogiri::XML(open(url))
    rescue Exception => e
      return {}, '' if e.message.include?('404')
    end
    metadata_source.original_mappings['bibid'] = bib_id
    metadata_source.set_metadata_mappings
  end

  def _set_structural_metadata_ark(ark_id)
    mapped_values = {}
    url = "#{MetadataSchema.config[:pqc_ark][:structural_http_lookup]}/#{ark_id.tr(':/','+=')}/#{MetadataSchema.config[:pqc_ark][:structural_lookup_suffix]}"
    begin
      data = Nokogiri::XML(open(url))
    rescue Exception => e
      return {}, '' if e.message.include?('404')
    end

    reading_direction = data.xpath('//record/pages/page').first['side'] == 'verso' ? 'right-to-left' : 'left-to-right'
    data.xpath('//record/pages/page').each_with_index do |page, index|
      mapped_values[index+1] = {
          'page_number' => page['number'],
          'sequence' => page['seq'],
          'reading_direction' => reading_direction,
          'side' => page['side'],
          'tocentry' => page['tocentry'],
          'identifier' => "#{ark_id.tr(':/','+=')}_#{page[:image]}",
          'file_name' => "#{page['image']}.tif",
          'description' => page['visiblepage']

      }
    end
    bib_id = data.at_xpath('//record/bib_id').children.first.text
    return mapped_values, bib_id
  end

  def action_description
    { :git_remote_initialized => 'Repo initialized' }
  end

  def mint_initial_ark
    Ezid::Identifier.mint
  end
end
