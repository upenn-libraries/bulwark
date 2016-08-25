class MetadataBuilder < ActiveRecord::Base
  include ActionView::Helpers::UrlHelper

  belongs_to :repo, :foreign_key => "repo_id"
  has_many :metadata_source, dependent: :destroy
  accepts_nested_attributes_for :metadata_source, allow_destroy: true
  validates_associated :metadata_source

  validates :parent_repo, presence: true

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
    unidentified = self.all_metadata_files - identified
    return unidentified
  end

  def refresh_metadata
    @working_path = self.repo.version_control_agent.clone
    self.metadata_source.each do |source|
      source.set_metadata_mappings(@working_path)
      source.last_extraction = DateTime.now
      source.save!
    end
    self.repo.version_control_agent.delete_clone
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
    self.repo.update_steps(:metadata_sources_selected)
  end

  def build_xml_files
    self.metadata_source.each do |source|
      source.build_xml if source.user_defined_mappings.present?
    end
    self.store_xml_preview
    self.last_xml_generated = DateTime.now()
    self.save!
    return {:success => "Preservation XML generated successfully.  See preview below."}
  end

  def transform_and_ingest(array)
    @vca = self.repo.version_control_agent
    working_path = @vca.clone
    transformed_repo_path = "#{Utils.config[:transformed_dir]}/#{@vca.remote_path.gsub("/","_")}"
    array.each do |p|
      key, val = p
      @vca.get(:get_location => val)
      @vca.unlock(val)
      unless canonical_identifier_check(val)
        @status = { :error => "No canonical identifier found for /#{self.repo.metadata_subdirectory}/#{File.basename(val)}.  Skipping ingest of this file."}
        next
      end
      Dir.mkdir(transformed_repo_path) && Dir.chdir(transformed_repo_path)
      `xsltproc #{Rails.root}/lib/tasks/sv.xslt #{val}`
      @status = self.repo.ingest(transformed_repo_path, working_path)
    end
    @vca.reset_hard
    @vca.delete_clone
    FileUtils.rm_rf(transformed_repo_path, :secure => true) if File.directory?(transformed_repo_path)
    return @status
  end

  def canonical_identifier_check(xml_file)
    doc = File.open(xml_file) { |f| Nokogiri::XML(f) }
    MetadataSchema.config[:canonical_identifier_path].each do |canon|
      @presence = doc.at("#{canon}").present?
    end
    return @presence
  end

  def qualified_metadata_files
    qualified_metadata_files = _available_files
    return qualified_metadata_files
  end

  def store_xml_preview
    working_path = self.repo.version_control_agent.clone
    get_location = "#{working_path}/#{self.repo.metadata_subdirectory}"
    self.repo.version_control_agent.get(:get_location => get_location)
    @sample_xml_docs = ""
    @file_links = Array.new
    Dir.glob("#{get_location}/*.xml") do |file|
      if File.exist?(file)
        pretty_file = file.gsub(working_path,"")
        @file_links << link_to(pretty_file, "##{file}")
        anchor_tag = content_tag(:a, "", :name=> file)
        sample_xml_content = File.open(file, "r"){|io| io.read}
        sample_xml_doc = REXML::Document.new sample_xml_content
        sample_xml = ""
        sample_xml_doc.write(sample_xml, 1)
        header = content_tag(:h2, "XML Sample for #{pretty_file}")
        xml_code = content_tag(:pre, "#{sample_xml}")
        @sample_xml_docs << content_tag(:div, anchor_tag << header << xml_code, :class => "doc")
      end
    end
    self.repo.version_control_agent.delete_clone
    @file_links_html = ""
    @file_links.each do |file_link|
      @file_links_html << content_tag(:li, file_link.html_safe)
    end
    self.xml_preview = content_tag(:ul, @file_links_html.html_safe) << @sample_xml_docs.html_safe
    self.save!
  end

  private

  def _available_files
    available_files = Array.new
    working_path = self.repo.version_control_agent.clone
    Dir.glob("#{working_path}/#{self.repo.metadata_subdirectory}/#{self.repo.format_types(self.repo.metadata_source_extensions)}") do |file|
      available_files << file.gsub(working_path,"")
    end
    self.repo.version_control_agent.delete_clone
    return available_files
  end

end
