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
    self.metadata_source.where(:source_type => MetadataSource.structural_types).each do |ms|
      ms.filenames.each do |file|
        file_path = "#{working_path}/#{self.repo.assets_subdirectory}/#{file}"
        self.repo.version_control_agent.unlock({:content => file_path}, working_path)
        validation_state = validate_file(file_path)
        self.repo.log_problem_file(file_path.gsub(working_path,''), validation_state) if validation_state.present?
        self.repo.version_control_agent.unlock({:content => self.repo.derivatives_subdirectory}, working_path)
        generate_preview(file_path,"#{working_path}/#{self.repo.derivatives_subdirectory}") unless validation_state.present?
        self.repo.version_control_agent.add({:content => file_path}, working_path)
        self.repo.version_control_agent.lock(file_path)
      end
    end
    self.repo.save!
    self.last_file_checks = DateTime.now
    self.save!
    self.repo.version_control_agent.add({:content => "#{working_path}/#{self.repo.derivatives_subdirectory}"}, working_path)
    self.repo.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.generated_previews'), working_path)
    self.repo.version_control_agent.push(working_path)
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
      xslt_file = self.metadata_source.any?{|ms| ms.source_type == 'bibliophilly'} ? 'bibliophilly' : 'pqc'
      Dir.chdir(working_path)
      `xsltproc #{Rails.root}/lib/tasks/#{xslt_file}.xslt #{file_path}`
      transformed_xml = "#{working_path}/#{Utils.config[:fedora_xml_derivative]}"
      fedora_xml = File.read(transformed_xml).gsub(repo.unique_identifier, repo.names.fedora)
      File.open(transformed_xml, 'w') {|f| f.puts fedora_xml }
      self.repo.ingest(transformed_xml, working_path)
    end
    self.repo.version_control_agent.add(working_path)
    self.repo.version_control_agent.add({:content => "#{working_path}/#{repo.derivatives_subdirectory}"}, working_path)
    self.repo.version_control_agent.add({:content => "#{working_path}/#{repo.admin_subdirectory}"}, working_path)
    self.repo.version_control_agent.lock
    self.repo.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.ingest_complete'), working_path)
    self.repo.version_control_agent.push(working_path)
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

  def generate_preview(file_name, derivatives_directory)
    preview = Utils::Derivatives::Preview.generate_copy(file_name, derivatives_directory)
    thumbnail = Utils::Derivatives::PreviewThumbnail.generate_copy(file_name, derivatives_directory)
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
    Dir.glob("#{get_location}/*.xml") do |file|
      if File.exist?(file)
        pretty_file = file.gsub(working_path,'')
        self.preserve.add(pretty_file, working_path) if File.basename(file) == self.repo.preservation_filename
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