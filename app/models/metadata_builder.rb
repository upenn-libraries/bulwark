require 'fastimage'

class MetadataBuilder < ActiveRecord::Base
  include ActionView::Helpers::UrlHelper
  include Utils::Process

  belongs_to :repo, :foreign_key => 'repo_id'
  has_many :metadata_source, dependent: :destroy
  accepts_nested_attributes_for :metadata_source, allow_destroy: true
  validates_associated :metadata_source

  validates :parent_repo, presence: true

  serialize :preserve, Set

  @@xml_tags = Array.new
  @@error_message = nil

  def parent_repo=(parent_repo)
    self[:parent_repo] = parent_repo
    @repo = Repo.find(parent_repo)
    self.repo = @repo
  end

  def parent_repo
    read_attribute(:parent_repo) || ''
  end

  def unidentified_files
    identified = (eval(self.source) + self.repo.preservation_filename)
    identified.uniq!
    self.all_metadata_files - identified
  end

  def refresh_metadata
    @working_path = self.repo.version_control_agent.clone
    get_mappings(@working_path)
    self.repo.version_control_agent.delete_clone(@working_path)
  end

  def get_mappings(working_path)
    self.metadata_source.each do |source|
      source.set_metadata_mappings(working_path)
      source.last_extraction = DateTime.now
      source.save!
    end
  end

  def determine_reading_direction
    default_direction = 'ltr'
    structural_source = self.metadata_source.where(:source_type => MetadataSource.structural_types).pluck(:user_defined_mappings).first
    lookup_key = structural_source.keys.first
    return structural_source[lookup_key]['reading_direction'].present? ? structural_source[lookup_key]['reading_direction'] : default_direction
  end

  def set_source(source_files)
    #TODO: Consider removing from MetadataBuilder
    self.source = source_files
    self.save!
    self.metadata_source.each do |mb_source|
      mb_source.delete unless source_files.include?(mb_source.path)
    end
    source_files.each do |source|
      self.metadata_source << MetadataSource.create(:path => source) unless MetadataSource.where(:metadata_builder_id => self.id, :path => source).pluck(:path).present?
    end
    self.save!
    self.repo.update_steps(:metadata_sources_selected)
  end

  def build_xml_files
    self.metadata_source.first.build_xml
    self.store_xml_preview
    self.last_xml_generated = DateTime.now
    self.save!
  end

  def save_input_sources(working_path)
    self.metadata_source.each do |source|
      save_input_source(working_path) if source.input_source.present? && source.input_source.downcase.start_with?('http')
      self.repo.version_control_agent.add({:content => "#{working_path}/#{self.metadata_builder.repo.admin_subdirectory}"}, working_path)
      self.repo.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.write_input_source'))
      self.repo.version_control_agent.push(working_path)
    end
  end

  def perform_file_checks_and_generate_previews
    self.repo.problem_files = {}
    working_path = self.repo.version_control_agent.clone
    file_checks_previews(working_path)
    Utils::Process.refresh_assets(working_path, self.repo)
    self.repo.version_control_agent.delete_clone(working_path)
  end

  def file_checks_previews(working_path)
    self.repo.version_control_agent.get({:location => "#{working_path}/#{self.repo.assets_subdirectory}"}, working_path)
    if self.metadata_source.where(:source_type => MetadataSource.structural_types).empty?
      Dir.glob("#{working_path}/#{self.repo.assets_subdirectory}/*.{#{self.repo.file_extensions.join(",")}}").each do |file_path|
        self.repo.version_control_agent.unlock({:content => file_path}, working_path)
        valid_file, validation_state = validate_file(file_path)
        self.repo.log_problem_file(file_path.gsub(working_path,''), validation_state) if validation_state.present?
        self.repo.version_control_agent.unlock({:content => self.repo.derivatives_subdirectory}, working_path)
        generate_preview(file_path, valid_file,"#{working_path}/#{self.repo.derivatives_subdirectory}") unless validation_state.present?
        self.repo.version_control_agent.add({:content => file_path}, working_path)
        self.repo.version_control_agent.lock(file_path, working_path)
      end
    else
      self.metadata_source.where(:source_type => MetadataSource.structural_types).each do |ms|
        ms.filenames.each do |file|
          file_path = "#{working_path}/#{self.repo.assets_subdirectory}/#{file}"
          self.repo.version_control_agent.unlock({:content => file_path}, working_path)
          valid_file, validation_state = validate_file(file_path)
          self.repo.log_problem_file(file_path.gsub(working_path,''), validation_state) if validation_state.present?
          self.repo.version_control_agent.unlock({:content => self.repo.derivatives_subdirectory}, working_path)
          generate_preview(file_path, valid_file,"#{working_path}/#{self.repo.derivatives_subdirectory}") unless validation_state.present?
          self.repo.version_control_agent.add({:content => file_path}, working_path)
          self.repo.version_control_agent.lock(file_path, working_path)
        end
      end
    end

    self.repo.save!
    self.last_file_checks = DateTime.now
    self.save!
    self.repo.version_control_agent.get({:location => "#{working_path}/."}, working_path)
    jhove = characterize_files(working_path, self.repo)
    self.repo.version_control_agent.add({:content => "#{repo.metadata_subdirectory}/#{jhove.filename}"}, working_path)
    self.repo.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.generated_preservation_metadata', :object_id => repo.names.fedora), working_path)
    self.repo.version_control_agent.add({:content => "#{working_path}/#{self.repo.derivatives_subdirectory}"}, working_path)
    self.repo.lock_keep_files(working_path)
    self.repo.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.generated_all_derivatives', :object_id => repo.names.fedora), working_path)
    self.repo.version_control_agent.push(working_path)
  end

  def get_structural_filenames
    filenames = []
    ms = self.metadata_source.where(:source_type => MetadataSource.structural_types).first
    ms.user_defined_mappings.each do |key,value|
      filenames << value[ms.file_field]
    end
    return filenames
  end

  def transform_and_ingest(array)
    working_path = self.repo.version_control_agent.clone
    ingest(working_path, array)
    Utils::Process.refresh_assets(working_path, self.repo)
    self.repo.version_control_agent.delete_clone(working_path)
  end

  def ingest(working_path,files_array)
    files_array.each do |file|
      file_path = "#{working_path}/#{file.last}".gsub('//','/')
      self.repo.version_control_agent.get({:location => file_path}, working_path)
      self.repo.version_control_agent.unlock({:content => file_path}, working_path)
      unless canonical_identifier_check(file_path)
        next
      end
      xslt_file = xslt_file_select
      Dir.chdir(working_path)
      `xsltproc #{Rails.root}/lib/tasks/#{xslt_file}.xslt #{file_path}`
      transformed_xml = "#{working_path}/#{Utils.config[:fedora_xml_derivative]}"
      fedora_xml = File.read(transformed_xml).gsub(self.repo.unique_identifier, repo.names.fedora)
      File.open(transformed_xml, 'w') {|f| f.puts fedora_xml }
      self.repo.version_control_agent.lock(file_path, working_path)
      self.repo.ingest(transformed_xml, working_path)
    end
  end

  def xslt_file_select
    if self.metadata_source.any?{|ms| ms.source_type == 'bibliophilly'}
      return 'bibliophilly'
    elsif self.metadata_source.any?{|ms| ms.source_type == 'kaplan'}
      return 'kaplan'
    elsif self.metadata_source.any?{|ms| ms.source_type == 'pap'}
      return 'pap'
    else
      return 'pqc'
    end
  end

  def canonical_identifier_check(xml_file)
    doc = File.open(xml_file) { |f| Nokogiri::XML(f) }
    MetadataSchema.config[:canonical_identifier_path].each do |canon|
      @presence = doc.at("#{canon}").present?
    end
    @presence
  end

  def qualified_metadata_files
    _available_files
  end

  def generate_preview(original_file, file, derivatives_directory)
    preview = Utils::Derivatives::Preview.generate_copy(original_file, file, derivatives_directory)
    thumbnail = Utils::Derivatives::PreviewThumbnail.generate_copy(original_file, file, derivatives_directory)
    return [preview, thumbnail]
  end

  def store_xml_preview
    working_path = self.repo.version_control_agent.clone
    read_and_store_xml(working_path)
    self.repo.version_control_agent.delete_clone(working_path)
  end

  def read_and_store_xml(working_path)
    get_location = "#{working_path}/#{self.repo.metadata_subdirectory}"
    self.repo.version_control_agent.get({:location => get_location}, working_path)
    sample_xml_docs = ''
    @file_links = Array.new
    files_to_store = []
    files_to_store << "#{get_location}/#{self.repo.preservation_filename}"
    files_to_store << "#{get_location}/#{Utils.config['mets_xml_derivative']}"
    files_to_store.each do |file|
      if File.exist?(file)
        pretty_file = file.gsub(working_path,'')
        self.preserve.add(pretty_file) if File.basename(file) == self.repo.preservation_filename
        @file_links << link_to(pretty_file, "##{file}")
        anchor_tag = content_tag(:a, '', :name=> file)
        sample_xml_content = File.open(file, 'r'){|io| io.read}
        sample_xml_doc = REXML::Document.new sample_xml_content
        sample_xml = ''
        sample_xml_doc.write(sample_xml, 1)
        header = content_tag(:h2, I18n.t('colenda.metadata_builders.xml_preview_header', :file => pretty_file))
        xml_code = content_tag(:pre, "#{sample_xml}")
        sample_xml_docs << content_tag(:div, anchor_tag << header << xml_code, :class => 'doc')
      end

    end
    @file_links_html = ''
    @file_links.each do |file_link|
      @file_links_html << content_tag(:li, file_link.html_safe)
    end
    self.xml_preview = content_tag(:ul, @file_links_html.html_safe) << sample_xml_docs.html_safe
    self.save!
  end

  def update_queue_status(queue_params)
    queue_status = nil
    if queue_params['remove_from_ingest_queue'].present?
      queue_status = nil if queue_params['remove_from_ingest_queue'].to_i > 0
      key = :remove_from_queue
    end
    if queue_params['queue_for_ingest'].present?
      queue_status = 'ingest' if queue_params['queue_for_ingest'].to_i > 0
      key = :review_complete
    end
    self.repo.queued = queue_status
    self.repo.save!
    return key
  end

  private

  def _available_files
    available_files = Array.new
    working_path = self.repo.version_control_agent.clone(:fsck => false)
    Dir.glob("#{working_path}/#{self.repo.metadata_subdirectory}/#{self.repo.format_types(self.repo.metadata_source_extensions)}") do |file|
      available_files << file.gsub(working_path,'')
    end
    self.repo.version_control_agent.delete_clone(working_path)
    available_files
  end

end