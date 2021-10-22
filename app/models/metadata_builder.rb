class MetadataBuilder < ActiveRecord::Base
  belongs_to :repo, :foreign_key => 'repo_id'
  has_many :metadata_source, dependent: :destroy
  accepts_nested_attributes_for :metadata_source, allow_destroy: true
  validates_associated :metadata_source

  validates :parent_repo, presence: true

  serialize :preserve, Set
  serialize :generated_metadata_files, JSON

  def parent_repo=(parent_repo)
    self[:parent_repo] = parent_repo
    @repo = Repo.find(parent_repo)
    self.repo = @repo
  end

  def parent_repo
    read_attribute(:parent_repo) || ''
  end

  # rubocop:disable Style/BlockDelimiters

  # Creates preservation xml. This xml file represents both the descriptive and
  # structural metadata.
  def preservation_xml
    descriptive_metadata = metadata_source.find_by(source_type: 'descriptive').user_defined_mappings
    structural_metadata = metadata_source.find_by(source_type: 'structural').user_defined_mappings

    Nokogiri::XML::Builder.new(encoding: 'UTF-8') { |xml|
      xml.root {
        xml.record {
          xml.uuid { xml.text repo.unique_identifier }

          descriptive_metadata.each do |field, values|
            values.each { |value| xml.send(field + '_', value) }
          end

          xml.pages {
            structural_metadata['sequence'].map do |asset|
              xml.page {
                asset.map do |field, value|
                  Array.wrap(value).each { |v| xml.send(field + '_', v) }
                end
              }
            end
          }
        }
      }
    }.to_xml
  end

  def mets_xml
    descriptive_metadata = metadata_source.find_by(source_type: 'descriptive').user_defined_mappings
    Nokogiri::XML::Builder.new { |xml|
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
  # rubocop:enable Style/BlockDelimiters
end
