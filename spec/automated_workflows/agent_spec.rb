require 'rails_helper'

RSpec.describe AutomatedWorkflows::Agent do

  describe '.new'

  describe '#proceed' do
    context 'when creating an item first time' do
      include_context 'manifest csv for object one'
      include_context 'cleanup test storage' # TODO: Can remove this once Repos cleanup after themselves.

      let(:repo) { Repo.find_by(unique_identifier: ark) }

      before do
        AutomatedWorkflows::Kaplan::Csv.generate_repos(csv_filepath)
        AutomatedWorkflows::Agent.new(
          AutomatedWorkflows::Kaplan,
          [ark],
          AutomatedWorkflows::Kaplan::Csv.config.endpoint('test'),
          steps_to_skip: ['ingest']
        ).proceed
      end

      context 'within cloned repo' do
        let(:working_dir) { repo.version_control_agent.clone }
        let(:git) { ExtendedGit.open(working_dir) }
        let(:whereis_result) { git.annex.whereis }
        let(:expected_mets) do
          <<~METS
            <?xml version="1.0"?>
            <METS:mets xmlns:METS="http://www.loc.gov/METS/" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/METS/ http://www.loc.gov/standards/mets/mets.xsd http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-0.xsd" OBJID="#{ark}"><METS:metsHdr CREATEDATE="2004-10-28T00:00:00.001" LASTMODDATE="2004-10-28T00:00:00.001"><METS:agent ROLE="CREATOR" TYPE="ORGANIZATION"><METS:name>University of Pennsylvania Libraries</METS:name></METS:agent></METS:metsHdr><METS:dmdSec ID="DM1"><METS:mdWrap MDTYPE="MODS"><METS:xmlData><mods:mods><mods:titleInfo><mods:title xmlns:image="http://www.modeshape.org/images/1.0" xmlns:space="preserve">Trade card; J. Rosenblatt &amp;amp; Co.; Baltimore, Maryland, United States; undated;</mods:title></mods:titleInfo><mods:originInfo><mods:issuance>monographic</mods:issuance></mods:originInfo><mods:language><mods:languageTerm xmlns:image="http://www.modeshape.org/images/1.0" xmlns:space="preserve" type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2.html" valueURI="http://id.loc.gov/vocabulary/iso639-2/ita">English</mods:languageTerm></mods:language><mods:name type="personal"/><mods:name type="corporate"><mods:namePart xmlns:image="http://www.modeshape.org/images/1.0" xmlns:space="preserve">J. Rosenblatt &amp;amp; Co.</mods:namePart></mods:name><mods:subject><mods:topic xmlns:image="http://www.modeshape.org/images/1.0" xmlns:space="preserve">House furnishings</mods:topic><mods:topic xmlns:image="http://www.modeshape.org/images/1.0" xmlns:space="preserve">Jewish merchants</mods:topic><mods:topic xmlns:image="http://www.modeshape.org/images/1.0" xmlns:space="preserve">Trade cards (advertising)</mods:topic></mods:subject><mods:subject><mods:geographic xmlns:image="http://www.modeshape.org/images/1.0" xmlns:space="preserve">Baltimore, Maryland, United States</mods:geographic><mods:geographic xmlns:image="http://www.modeshape.org/images/1.0" xmlns:space="preserve">Maryland, United States</mods:geographic></mods:subject><mods:physicalDescription><mods:extent>J. Rosenblatt &amp;amp; Co.: Importers: Earthenware, China, Majolica, Novelties32 South Howard Street, Baltimore, MD</mods:extent><mods:digitalOrigin>reformatted digital</mods:digitalOrigin><mods:reformattingQuality>preservation</mods:reformattingQuality><mods:form authority="marcform" authorityURI="http://www.loc.gov/standards/valuelist/marcform.html">print</mods:form></mods:physicalDescription><mods:abstract displayLabel="Summary"/><mods:note type="bibliography"/><mods:note type="citation/reference"/><mods:note type="ownership"/><mods:note type="preferred citation"/><mods:note type="additional physical form"/><mods:note type="publications"/><mods:identifier type="uuid">#{ark}</mods:identifier></mods:mods></METS:xmlData></METS:mdWrap></METS:dmdSec></METS:mets>
          METS
        end
        let(:expected_preservation) do
          <<~PRESERVATION
            <?xml version="1.0" encoding="UTF-8"?>
            <root>
              <record>
                <uuid>#{ark}</uuid>
                <description>J. Rosenblatt &amp;amp; Co.: Importers: Earthenware, China, Majolica, Novelties</description>
                <description>32 South Howard Street, Baltimore, MD</description>
                <title>Trade card; J. Rosenblatt &amp;amp; Co.; Baltimore, Maryland, United States; undated;</title>
                <collection>Arnold and Deanne Kaplan Collection of Early American Judaica (University of Pennsylvania)</collection>
                <call_number>Arc.MS.56</call_number>
                <item_type>Trade cards</item_type>
                <language>English</language>
                <date>undated</date>
                <corporate_name>J. Rosenblatt &amp;amp; Co.</corporate_name>
                <geographic_subject>Baltimore, Maryland, United States</geographic_subject>
                <geographic_subject>Maryland, United States</geographic_subject>
                <rights>http://rightsstatements.org/page/NoC-US/1.0/?</rights>
                <subject>House furnishings</subject>
                <subject>Jewish merchants</subject>
                <subject>Trade cards (advertising)</subject>
                <pages>
                  <page>
                    <sequence>1</sequence>
                    <page_number>1</page_number>
                    <reading_direction>left-to-right</reading_direction>
                    <side></side>
                    <file_name>front.tif</file_name>
                    <item_type>[]</item_type>
                  </page>
                  <page>
                    <sequence>2</sequence>
                    <page_number>2</page_number>
                    <reading_direction>left-to-right</reading_direction>
                    <side></side>
                    <file_name>back.tif</file_name>
                    <item_type>[]</item_type>
                  </page>
                </pages>
              </record>
            </root>
          PRESERVATION
        end

        it 'contains assets files' do
          expect(whereis_result.map(&:filepath)).to include('data/assets/back.tif', 'data/assets/front.tif')
          expect(whereis_result['data/assets/back.tif'].locations.map(&:description)).to include '[local]'
          expect(whereis_result['data/assets/front.tif'].locations.map(&:description)).to include '[local]'
        end

        it 'contains metadata files' do
          files = ['data/metadata/metadata.xlsx', 'data/metadata/mets.xml', 'data/metadata/preservation.xml']
          expect(whereis_result.map(&:filepath)).to include(*files)
          files.each do |filepath|
            expect(whereis_result[filepath].locations.map(&:description)).to include '[local]'
          end
        end

        it 'generated metadata files contain expected data' do
          git.annex.get(repo.metadata_subdirectory)
          expect(File.read(File.join(working_dir, repo.metadata_subdirectory, 'mets.xml'))).to be_equivalent_to expected_mets
          expect(File.read(File.join(working_dir, repo.metadata_subdirectory, 'preservation.xml'))).to be_equivalent_to expected_preservation
        end

        it 'contains derivatives' do
          derivatives = ['.derivs/back.tif.jpeg', '.derivs/back.tif.thumb.jpeg', '.derivs/front.tif.jpeg', '.derivs/front.tif.thumb.jpeg']
          expect(whereis_result.map(&:filepath)).to include(*derivatives)
          derivatives.each do |filepath|
            expect(whereis_result[filepath].locations.map(&:description)).to include '[local]'
          end
        end

        it 'contains .keep files only added via git' do
          expect(
            whereis_result.map(&:filepath).keep_if { |path| File.basename(path) == '.keep' }
          ).to be_empty
        end

        it 'generates expected images_to_render hash' do
          expect(repo.images_to_render).to match({
            'iiif' => {
              'images' => [
                "/#{repo.names.bucket}%2F#{git.annex.lookupkey('.derivs/front.tif.jpeg')}/info.json",
                "/#{repo.names.bucket}%2F#{git.annex.lookupkey('.derivs/back.tif.jpeg')}/info.json"
              ],
              'reading_direction' => 'left-to-right'
            }
          })
        end
      end

      it 'generates expected metadata sources objects' do
        descriptive_metadata = repo.metadata_builder.metadata_source.find_by(path: 'data/metadata/metadata.xlsx')
        expect(descriptive_metadata.original_mappings).to include(
          'Filename(s)' => ['front.tif; back.tif'],
          'Title' => ['Trade card; J. Rosenblatt & Co.; Baltimore, Maryland, United States; undated;']
        )
      end

      context 'when ingesting content' do
        include_context 'stub successful EZID requests'

        before do
          AutomatedWorkflows::Agent.new(
            AutomatedWorkflows::IngestOnly,
            [ark],
            '',
            steps_to_skip: AutomatedWorkflows.config[:ingest_only][:steps_to_skip]
          ).proceed
        end

        it 'creates fedora object' do
          fedora_object = ActiveFedora::Base.find(repo.names.fedora)
          expect(fedora_object).not_to be nil
          expect(fedora_object.title).to match_array('Trade card; J. Rosenblatt &amp; Co.; Baltimore, Maryland, United States; undated;')
          expect(fedora_object.date).to match_array('undated')
          expect(fedora_object.item_type).to match_array('Trade cards')
          expect(fedora_object.corporate_name).to match_array('J. Rosenblatt &amp; Co.')
          expect(fedora_object.geographic_subject).to match_array(['Baltimore, Maryland, United States', 'Maryland, United States'])
          expect(fedora_object.description).to match_array(['J. Rosenblatt &amp; Co.: Importers: Earthenware, China, Majolica, Novelties', '32 South Howard Street, Baltimore, MD'])
          expect(fedora_object.language).to match_array('English')
          expect(fedora_object.rights).to match_array('http://rightsstatements.org/page/NoC-US/1.0/?')
          expect(fedora_object.subject).to match_array(['House furnishings', 'Jewish merchants', 'Trade cards (advertising)'])
          expect(fedora_object.display_call_number).to match_array('Arc.MS.56')
          expect(fedora_object.collection).to match_array('Arnold and Deanne Kaplan Collection of Early American Judaica (University of Pennsylvania)')
          expect(fedora_object.unique_identifier).to eql ark
          expect(fedora_object.thumbnail).to be_a ActiveFedora::File
        end

        it 'creates solr document' do
          document = Blacklight.default_index.find(repo.names.fedora).docs.first
          expect(document['active_fedora_model_ssi']).to eql 'PrintedWork'
          expect(document['title_ssim']).to match_array('Trade card; J. Rosenblatt &amp; Co.; Baltimore, Maryland, United States; undated;')
          expect(document['unique_identifier_tesim']).to match_array(ark)
        end

        it 'adds thumbnail_location to Repo' do
          url = ActiveFedora::Base.find(repo.names.fedora).thumbnail.ldp_source.head.headers['Content-Type'].match(/url="(?<url>[^"]*)"/)[:url]
          expect(repo.thumbnail_location).to eql Addressable::URI.parse(url).path
        end
      end

      context 'when updating a digital object' do
        let(:repo) { Repo.find_by(unique_identifier: ark) }
        let(:updated_preservation) do
          <<~PRESERVATION
            <?xml version="1.0" encoding="UTF-8"?>
            <root>
              <record>
                <uuid>#{ark}</uuid>
                <description>J. Rosenblatt &amp;amp; Co.: Importers: Earthenware, China, Majolica, Novelties</description>
                <description>32 South Howard Street, Baltimore, MD</description>
                <description>New and important facts.</description>
                <title>Trade card; J. Rosenblatt &amp;amp; Co.; Baltimore, Maryland, United States; undated;</title>
                <collection>Arnold and Deanne Kaplan Collection of Early American Judaica (University of Pennsylvania)</collection>
                <call_number>Arc.MS.56</call_number>
                <item_type>Trade cards</item_type>
                <language>English</language>
                <date>1843</date>
                <corporate_name>J. Rosenblatt &amp;amp; Co.</corporate_name>
                <geographic_subject>Baltimore, Maryland, United States</geographic_subject>
                <geographic_subject>Maryland, United States</geographic_subject>
                <rights>http://rightsstatements.org/page/NoC-US/1.0/?</rights>
                <subject>Jewish merchants</subject>
                <subject>Trade cards (advertising)</subject>
                <pages>
                  <page>
                    <sequence>1</sequence>
                    <page_number>1</page_number>
                    <reading_direction>left-to-right</reading_direction>
                    <side></side>
                    <file_name>front.tif</file_name>
                    <item_type>[]</item_type>
                  </page>
                  <page>
                    <sequence>2</sequence>
                    <page_number>2</page_number>
                    <reading_direction>left-to-right</reading_direction>
                    <side></side>
                    <file_name>back.tif</file_name>
                    <item_type>[]</item_type>
                  </page>
                </pages>
              </record>
            </root>
          PRESERVATION
        end
        let(:updated_mets) do
          <<~METS
            <?xml version="1.0"?>
            <METS:mets xmlns:METS="http://www.loc.gov/METS/" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.loc.gov/METS/ http://www.loc.gov/standards/mets/mets.xsd http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-0.xsd" OBJID="#{ark}"><METS:metsHdr CREATEDATE="2004-10-28T00:00:00.001" LASTMODDATE="2004-10-28T00:00:00.001"><METS:agent ROLE="CREATOR" TYPE="ORGANIZATION"><METS:name>University of Pennsylvania Libraries</METS:name></METS:agent></METS:metsHdr><METS:dmdSec ID="DM1"><METS:mdWrap MDTYPE="MODS"><METS:xmlData><mods:mods><mods:titleInfo><mods:title xmlns:image="http://www.modeshape.org/images/1.0" xmlns:space="preserve">Trade card; J. Rosenblatt &amp;amp; Co.; Baltimore, Maryland, United States; undated;</mods:title></mods:titleInfo><mods:originInfo><mods:issuance>monographic</mods:issuance></mods:originInfo><mods:language><mods:languageTerm xmlns:image="http://www.modeshape.org/images/1.0" xmlns:space="preserve" type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2.html" valueURI="http://id.loc.gov/vocabulary/iso639-2/ita">English</mods:languageTerm></mods:language><mods:name type="personal"/><mods:name type="corporate"><mods:namePart xmlns:image="http://www.modeshape.org/images/1.0" xmlns:space="preserve">J. Rosenblatt &amp;amp; Co.</mods:namePart></mods:name><mods:subject><mods:topic xmlns:image="http://www.modeshape.org/images/1.0" xmlns:space="preserve">Jewish merchants</mods:topic><mods:topic xmlns:image="http://www.modeshape.org/images/1.0" xmlns:space="preserve">Trade cards (advertising)</mods:topic></mods:subject><mods:subject><mods:geographic xmlns:image="http://www.modeshape.org/images/1.0" xmlns:space="preserve">Baltimore, Maryland, United States</mods:geographic><mods:geographic xmlns:image="http://www.modeshape.org/images/1.0" xmlns:space="preserve">Maryland, United States</mods:geographic></mods:subject><mods:physicalDescription><mods:extent>J. Rosenblatt &amp;amp; Co.: Importers: Earthenware, China, Majolica, Novelties32 South Howard Street, Baltimore, MDNew and important facts.</mods:extent><mods:digitalOrigin>reformatted digital</mods:digitalOrigin><mods:reformattingQuality>preservation</mods:reformattingQuality><mods:form authority="marcform" authorityURI="http://www.loc.gov/standards/valuelist/marcform.html">print</mods:form></mods:physicalDescription><mods:abstract displayLabel="Summary"/><mods:note type="bibliography"/><mods:note type="citation/reference"/><mods:note type="ownership"/><mods:note type="preferred citation"/><mods:note type="additional physical form"/><mods:note type="publications"/><mods:identifier type="uuid">#{ark}</mods:identifier></mods:mods></METS:xmlData></METS:mdWrap></METS:dmdSec></METS:mets>
          METS
        end
        let(:working_dir) { repo.version_control_agent.clone }
        let(:git) { ExtendedGit.open(working_dir) }

        before do
          filepath = Rails.root.join('tmp', 'manifest.csv').to_s
          File.open(filepath, 'w') do |f|
            manifest = <<~MANIFEST
              share,path,unique_identifier,timestamp,directive_name,status
              test,object_one_update,#{repo.unique_identifier},,"#{repo.human_readable_name}",
            MANIFEST
            f.write(manifest)
          end
          AutomatedWorkflows::Kaplan::Csv.generate_repos(filepath)
          AutomatedWorkflows::Agent.new(
            AutomatedWorkflows::Kaplan,
            [ark],
            AutomatedWorkflows::Kaplan::Csv.config.endpoint('test'),
            steps_to_skip: ['ingest']
          ).proceed
        end

        # For some reason JHOVE is hanging on this test. Skipping for now because we will soon retire this code.
        xit 'contains updated metadata' do
          git.annex.get(repo.metadata_subdirectory)
          expect(File.read(File.join(working_dir, repo.metadata_subdirectory, 'mets.xml'))).to be_equivalent_to updated_mets
          expect(File.read(File.join(working_dir, repo.metadata_subdirectory, 'preservation.xml'))).to be_equivalent_to updated_preservation
        end
      end
    end
  end
end
