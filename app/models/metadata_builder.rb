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
  serialize :generated_metadata_files, JSON

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

  # Creates preservation xml. This xml file represents both the descriptive and
  # structural metadata.
  def preservation_xml
    descriptive_metadata = metadata_source.find_by(source_type: 'descriptive').user_defined_mappings
    structural_metadata = metadata_source.find_by(source_type: 'structural').user_defined_mappings

    xml_content = Nokogiri::XML::Builder.new(encoding: 'UTF-8') { |xml|
      xml.root {
        xml.record {
          xml.uuid { xml.text repo.unique_identifier }

          descriptive_metadata.each do |field, values|
            values.each { |value| xml.send(field + '_', value) }
          end

          xml.pages {
            structural_metadata['sequence'].map do |asset|
              xml.page {
                asset.map { |field, value| xml.send(field, value) }
              }
            end
          }
        }
      }
    }.to_xml
  end

  def mets_xml
    descriptive_metadata = metadata_source.find_by(source_type: 'descriptive').user_defined_mappings
    xml_content = Nokogiri::XML::Builder.new { |xml|
      xml['METS'].mets(
        'xmlns:METS' => 'http://www.loc.gov/METS/',
        'xmlns:mods' => 'http://www.loc.gov/mods/v3',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xsi:schemaLocation' => 'http://www.loc.gov/METS/ http://www.loc.gov/standards/mets/mets.xsd http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-0.xsd',
        'OBJID' => repo.unique_identifier
      ) {
        xml['METS'].metsHdr('CREATEDATE' => '2004-10-28T00:00:00.001', 'LASTMODDATE' => '2004-10-28T00:00:00.001') {
          xml['METS'].agent('ROLE' => 'CREATOR', 'TYPE' => 'ORGANIZATION') {
            xml['METS'].name {
              xml.text 'University of Pennsylvania Libraries'
            }
          }
        }
        xml['METS'].dmdSec('ID' => 'DM1') {
          xml['METS'].mdWrap('MDTYPE' => 'MODS') {
            xml['METS'].xmlData {
              xml['mods'].mods {
                xml['mods'].titleInfo {
                  descriptive_metadata['title']&.each { |title|
                    xml['mods'].title { xml.text title }
                  }
                }
                xml['mods'].originInfo {
                  xml['mods'].issuance { xml.text 'monographic' }
                }
                xml['mods'].language {
                  descriptive_metadata['language']&.each { |language|
                    xml['mods'].languageTerm(
                      'type' => 'text',
                      'authority' => 'iso639-2b',
                      'authorityURI' => 'http://id.loc.gov/vocabulary/iso639-2.html',
                      'valueURI' => 'http://id.loc.gov/vocabulary/iso639-2/ita'
                     ) { xml.text language }
                  }

                }
                xml['mods'].name(type: 'personal') {
                  descriptive_metadata['personal_name']&.each { |name|
                    xml['mods'].namePart { xml.text name }
                  }
                }
                xml['mods'].name(type: 'corporate') {
                  descriptive_metadata['corporate_name']&.each { |name|
                    xml['mods'].namePart { xml.text name }
                  }
                }
                xml['mods'].subject {
                  descriptive_metadata['subject']&.each { |subject|
                    xml['mods'].topic { xml.text subject }
                  }
                }
                xml['mods'].subject {
                  descriptive_metadata['geographic_subject']&.each { |subject|
                    xml['mods'].geographic { xml.text subject }
                  }
                }
                xml['mods'].physicalDescription {
                  xml['mods'].extent {
                    xml.text descriptive_metadata['description']&.join
                  }
                  xml['mods'].digitalOrigin { xml.text 'reformatted digital' }
                  xml['mods'].reformattingQuality { xml.text 'preservation' }
                  xml['mods'].form('authority' => 'marcform', 'authorityURI' => 'http://www.loc.gov/standards/valuelist/marcform.html') {
                    xml.text 'print'
                  }
                }
                xml['mods'].abstract(displayLabel: 'Summary') {
                  xml.text descriptive_metadata['abstract']&.join
                }
                xml['mods'].note(type: 'bibliography') {
                  descriptive_metadata['bibliography_note']&.join
                }
                xml['mods'].note(type: 'citation/reference') {
                  descriptive_metadata['citation_note']&.join
                }
                xml['mods'].note(type: 'ownership') {
                  descriptive_metadata['ownership_note']&.join
                }
                xml['mods'].note(type: 'preferred citation') {
                  descriptive_metadata['preferred_citation_note']&.join
                }
                xml['mods'].note(type: 'additional physical form') {
                  descriptive_metadata['additional_physical_form_note']&.join
                }
                xml['mods'].note(type: 'publications') {
                  descriptive_metadata['publications_note']&.join
                }
                xml['mods'].identifier(type: 'uuid') { xml.text repo.unique_identifier }
              }
            }
          }
        }
      }
    }.to_xml
  end

  # Doesn't seem to be called anywhere.
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
    self.repo.save!
    working_path = self.repo.version_control_agent.clone
    file_checks_previews(working_path)
    Utils::Process.refresh_assets(working_path, self.repo)
    self.repo.version_control_agent.delete_clone(working_path)
  end

  def file_checks_previews(working_path)
    self.repo.version_control_agent.get({ location: "#{working_path}/#{self.repo.assets_subdirectory}"}, working_path)
    self.repo.version_control_agent.get({ location: self.repo.derivatives_subdirectory }, working_path)
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
    self.repo.version_control_agent.add({ content: self.repo.derivatives_subdirectory, include_dotfiles: true }, working_path)
    self.repo.version_control_agent.lock('.derivs', working_path)
    self.repo.version_control_agent.commit(I18n.t('colenda.version_control_agents.commit_messages.generated_all_derivatives', :object_id => repo.names.fedora), working_path)
    self.repo.version_control_agent.push(working_path)
  end

  def get_structural_filenames
    ms = self.metadata_source.where(source_type: MetadataSource.structural_types).first
    return nil if ms.nil?
    ms.filenames
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

      doc = Nokogiri::XML(File.read(file_path))
      xslt = Nokogiri::XSLT(File.read("#{Rails.root}/lib/tasks/#{xslt_file}.xslt"))
      output = xslt.transform(doc).to_s.gsub(self.repo.unique_identifier, repo.names.fedora)
      fedora_xml_filepath = File.join(working_path, 'fedora.xml')
      File.write(fedora_xml_filepath, output)

      self.repo.version_control_agent.lock(file_path, working_path)
      self.repo.ingest(fedora_xml_filepath, working_path)
    end
  end

  def xslt_file_select
    if self.metadata_source.any?{|ms| ms.source_type == 'kaplan'}
      return 'kaplan'
    elsif self.metadata_source.any?{|ms| ms.source_type == 'pap'}
      return 'pap'
    elsif self.metadata_source.any?{|ms| ms.source_type == 'pqc_desc'}
      return 'pap'
    elsif self.metadata_source.any?{|ms| ms.source_type == 'pqc_combined_desc'}
      return 'pqc_combined'
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

  # Going forward we are going to stop storing the xml_preview on this object.
  # We can get the data from CEPH instead of storing it in the database and
  # bloating the database.
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
