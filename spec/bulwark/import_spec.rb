require 'rails_helper'

RSpec.describe Bulwark::Import do

  describe '.new'

  describe '.validation' do
    before do
      stub_request(:get, /#{Ezid::Client.config.host}\/id\/.*/)
        .with(
          basic_auth: [Ezid::Client.config.user, Ezid::Client.config.password],
          headers: { 'Content-Type': 'text/plain; charset=UTF-8' }
        )
        .to_return { |request|
          {
            status: 200,
            headers: { 'Content-Type': 'text/plain; charset=UTF-8' },
            body: "success: #{request.uri.path.split('/', 3).last}"
          }
        }
    end

    context 'when type is invalid' do
      subject { described_class.new(type: 'invalid') }

      it 'adds error' do
        expect(subject.validate).to be false
        expect(subject.errors).to include('"invalid" is not a valid import type')
      end
    end

    context 'when creating new object without required values' do
      subject { described_class.new(type: Bulwark::Import::CREATE) }

      it 'adds errors' do
        expect(subject.validate).to be false
        expect(subject.errors).to include('structural_metadata must be provided to create an object')
        expect(subject.errors).to include('descriptive_metadata must be provided to create an object')
        expect(subject.errors).to include('"assets.path" and "assets.drive" must be provided to create an object')
        expect(subject.errors).to include('"directive" must be provided to create an object')
      end
    end

    context 'when creating a new object with a unique_identifier already in use' do
      include_context 'stub successful EZID requests' # Stubbing EZID request needed when creating a new repo.

      let(:ark) { FactoryBot.create(:repo).unique_identifier }

      subject { described_class.new(type: Bulwark::Import::CREATE, unique_identifier: ark) }

      it 'adds errors' do
        expect(subject.validate).to be false
        expect(subject.errors).to include("\"#{ark}\" already belongs to an object. Cannot create new object with given unique identifier.")
      end
    end

    context 'when creating a new object with an unminted ark' do

      before do
        # Stub request to get EZID
        stub_request(:get, /#{Ezid::Client.config.host}\/id\/ark:\/99999\/fk4invalid/)
          .with(
            basic_auth: [Ezid::Client.config.user, Ezid::Client.config.password],
            headers: { 'Content-Type': 'text/plain; charset=UTF-8' }
          )
          .to_return { |request|
            {
              status: 400,
              headers: { 'Content-Type': 'text/plain; charset=UTF-8' },
              body: "error: bad request - invalid identifier"
            }
          }
      end
      subject { described_class.new(type: Bulwark::Import::CREATE, unique_identifier: 'ark:/99999/fk4invalid') }

      it 'adds error' do
        expect(subject.validate).to be false
        expect(subject.errors).to include('"ark:/99999/fk4invalid" is not minted')
      end
    end

    context 'when updating an object without a unique_identifier' do
      subject { described_class.new(type: Bulwark::Import::UPDATE) }

      it 'adds error' do
        expect(subject.validate).to be false
        expect(subject.errors).to include '"unique_identifier" must be provided when updating an object'
      end
    end

    context 'when updating an object with an invalid unique_identifier' do
      subject { described_class.new(type: Bulwark::Import::UPDATE, unique_identifier: 'ark:/99999/fk4invalid') }
      it 'adds error' do
        expect(subject.validate).to be false
        expect(subject.errors).to include '"unique_identifier" does not belong to an object. Cannot update object.'
      end
    end

    context 'when asset drive is invalid' do
      subject { described_class.new(assets: { 'drive' => 'invalid' }) }

      it 'adds error' do
        expect(subject.validate).to be false
        expect(subject.errors).to include 'asset drive invalid'
      end
    end

    context 'when asset path is invalid' do
      subject { described_class.new(assets: { drive: 'test', path: 'invalid/something' }) }

      it 'adds error' do
        expect(subject.validate).to be false
        expect(subject.errors).to include 'asset path invalid'
      end
    end

    context 'when structural filenames and file are provided' do
      subject { described_class.new(structural_metadata: { filenames: 'something', asset: 'something', drive: 'test' }) }

      it 'adds error' do
        expect(subject.validate).to be false
        expect(subject.errors).to include 'cannot provide structural metadata two different ways'
      end
    end

    context 'when structural drive is invalid' do
      subject { described_class.new(structural_metadata: { 'drive' => 'invalid' }) }

      it 'adds error' do
        expect(subject.validate).to be false
        expect(subject.errors).to include 'structural drive invalid'
      end
    end

    context 'when structural path is invalid' do
      subject { described_class.new(structural_metadata: { drive: 'test', path: 'invalid/something' }) }

      it 'adds error' do
        expect(subject.validate).to be false
        expect(subject.errors).to include 'structural path invalid'
      end
    end
  end

  describe '.process' do
    include_context 'stub successful EZID requests'

    let(:created_by) { User.create(email: 'test@example.com') }

    context 'when creating a new digital object' do
      let(:descriptive_metadata) do
        {
          'collection' => ['Arnold and Deanne Kaplan Collection of Early American Judaica (University of Pennsylvania)'],
          'call_number' => ['Arc.MS.56'],
          'item_type' => ['Trade cards'],
          'language' => ['English'],
          'date' => ['undated'],
          'corporate_name' => ['J. Rosenblatt & Co.'],
          'geographic_subject' => ['Baltimore, Maryland, United States', 'Maryland, United States'],
          'description' =>['J. Rosenblatt & Co.: Importers: Earthenware, China, Majolica, Novelties', '32 South Howard Street, Baltimore, MD'],
          'rights' => ['http://rightsstatements.org/page/NoC-US/1.0/?'],
          'subject' => ['House furnishings', 'Jewish merchants', 'Trade cards (advertising)'],
          'title' => ['Trade card; J. Rosenblatt & Co.; Baltimore, Maryland, United States; undated;']
        }
      end
      let(:structural_metadata) do
        {
          'sequence' => [
            { 'sequence' => '1', 'filename' => 'front.tif' },
            { 'sequence' => '2', 'filename' => 'back.tif' }
          ]
        }
      end
      let(:import) do
        described_class.new(
          type: Bulwark::Import::CREATE,
          directive: 'object_one',
          assets: { drive: 'test', path: 'object_one' },
          descriptive_metadata: descriptive_metadata,
          structural_metadata: { 'filenames' => 'front.tif; back.tif' },
          created_by: created_by
        )
      end
      let(:repo) { Repo.find_by(unique_identifier: result.unique_identifier) }
      let(:working_dir) { repo.version_control_agent.clone }
      let(:git) { ExtendedGit.open(working_dir) }
      let(:whereis_result) { git.annex.whereis }

      let(:result) { import.process }

      let(:expected_mets) { fixture_to_xml('example_objects', 'object_one', 'mets.xml') }
      let(:expected_preservation) { fixture_to_xml('example_objects', 'object_one', 'preservation.xml') }
      let(:expected_structural) { fixture_to_str('example_objects', 'object_one', 'structural_metadata.csv') }
      let(:expected_descriptive) { fixture_to_str('example_objects', 'object_one', 'descriptive_metadata.csv') }

      it 'expect result to be successful' do
        expect(result.status).to be Bulwark::Import::Result::SUCCESS
      end

      it 'sets flag on repo', focus: true do
        expect(repo.new_format).to be true
      end

      it 'creates descriptive metadata source' do
        metadata_source = repo.descriptive_metadata
        expect(metadata_source.source_type).to eql 'descriptive'
        expect(metadata_source.original_mappings).to eql descriptive_metadata
        expect(metadata_source.user_defined_mappings).to eql descriptive_metadata
        expect(metadata_source.remote_location).to eql "#{repo.names.bucket}/#{git.annex.lookupkey('data/metadata/descriptive_metadata.csv')}"
      end

      it 'creates structural metadata source' do
        metadata_source = repo.structural_metadata
        expect(metadata_source.source_type).to eql 'structural'
        expect(metadata_source.original_mappings).to eql structural_metadata
        expect(metadata_source.user_defined_mappings).to eql structural_metadata
        expect(metadata_source.remote_location).to eql "#{repo.names.bucket}/#{git.annex.lookupkey('data/metadata/structural_metadata.csv')}"
      end

      it 'creates thumbnail' do
        expect(whereis_result.map(&:filepath)).to include('.derivs/thumbnails/front.jpeg')
        expect(whereis_result['.derivs/thumbnails/front.jpeg'].locations.map(&:description)).to include '[local]'
        expect(repo.thumbnail).to eql 'front.tif'
        expect(repo.thumbnail_location).to eql "#{repo.names.bucket}/#{git.annex.lookupkey('.derivs/thumbnails/front.jpeg')}"
      end

      it 'contains assets files' do
        expect(whereis_result.map(&:filepath)).to include('data/assets/back.tif', 'data/assets/front.tif')
        expect(whereis_result['data/assets/back.tif'].locations.map(&:description)).to include '[local]'
        expect(whereis_result['data/assets/front.tif'].locations.map(&:description)).to include '[local]'
      end

      it 'contains metadata files' do
        files = ['data/metadata/descriptive_metadata.csv', 'data/metadata/structural_metadata.csv', 'data/metadata/mets.xml', 'data/metadata/preservation.xml']
        expect(whereis_result.map(&:filepath)).to include(*files)
        files.each do |filepath|
          expect(whereis_result[filepath].locations.map(&:description)).to include '[local]'
        end
      end

      it 'given metadata files contain expected data' do
        git.annex.get(repo.metadata_subdirectory)
        expect(File.read(File.join(working_dir, repo.metadata_subdirectory, 'structural_metadata.csv'))).to eql expected_structural
        expect(File.read(File.join(working_dir, repo.metadata_subdirectory, 'descriptive_metadata.csv'))).to eql expected_descriptive
      end

      it 'generated metadata files contain expected data' do
        git.annex.get(repo.metadata_subdirectory)
        expect(Nokogiri::XML(File.read(File.join(working_dir, repo.metadata_subdirectory, 'preservation.xml')))).to be_equivalent_to(expected_preservation).ignoring_content_of('uuid')
        expect(Nokogiri::XML(File.read(File.join(working_dir, repo.metadata_subdirectory, 'mets.xml')))).to be_equivalent_to(expected_mets).ignoring_attr_values('OBJID').ignoring_content_of('mods|identifier')
      end

      it 'links to generated metadata files are stored' do
        expect(repo.metadata_builder.generated_metadata_files).to match(
          'data/metadata/preservation.xml' => "#{repo.names.bucket}/#{git.annex.lookupkey('data/metadata/preservation.xml')}",
          'data/metadata/mets.xml' => "#{repo.names.bucket}/#{git.annex.lookupkey('data/metadata/mets.xml')}"
        )
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

      # Updating digital object with additional metadata and an additional asset.
      context 'when updating a digital object' do
        let(:updated_descriptive_metadata) do
          {
            'description' => [
              'J. Rosenblatt & Co.: Importers: Earthenware, China, Majolica, Novelties', '32 South Howard Street, Baltimore, MD', 'New and important facts.'
            ],
            'subject' => ['Jewish merchants', 'Trade cards (advertising)'],
            'date' => ['1843']
          }
        end
        let(:updated_structural_metadata) do
          {
            'sequence' => [
              { 'sequence' => '1', 'filename' => 'new.tif' },
              { 'sequence' => '2', 'filename' => 'front.tif' },
              { 'sequence' => '3', 'filename' => 'back.tif' }
            ]
          }
        end
        let(:updated_descriptive) { fixture_to_str('example_objects', 'object_one_update', 'descriptive_metadata.csv') }
        let(:updated_structural) { fixture_to_str('example_objects', 'object_one_update', 'structural_metadata.csv') }
        let(:updated_mets) { fixture_to_xml('example_objects', 'object_one_update', 'mets.xml') }
        let(:updated_preservation) { fixture_to_xml('example_objects', 'object_one_update', 'preservation.xml') }
        let(:updated_result) do
          described_class.new(
            type: Bulwark::Import::UPDATE,
            unique_identifier: result.unique_identifier,
            descriptive_metadata: updated_descriptive_metadata,
            assets: { drive: 'test', path: 'object_one_update/new.tif' },
            structural_metadata: { filenames: 'new.tif; front.tif; back.tif' },
            created_by: created_by
          ).process
        end

        let(:updated_repo) { Repo.find_by(unique_identifier: updated_result.unique_identifier) }
        let(:updated_working_dir) { updated_repo.version_control_agent.clone }
        let(:updated_git) { ExtendedGit.open(updated_working_dir) }
        let(:updated_whereis_result) { updated_git.annex.whereis }

        it 'update is successful' do
          expect(updated_result.status).to be Bulwark::Import::Result::SUCCESS
        end

        it 'contains additional asset and derivatives' do
          new_asset_and_derivatives = ['.derivs/new.tif.jpeg', '.derivs/new.tif.thumb.jpeg', 'data/assets/new.tif']
          expect(updated_whereis_result.map(&:filepath)).to include(*new_asset_and_derivatives)
          new_asset_and_derivatives.each do |filepath|
            expect(updated_whereis_result[filepath].locations.map(&:description)).to include '[local]'
          end
        end

        it 'updated thumbnail' do
          expect(updated_whereis_result.map(&:filepath)).to include('.derivs/thumbnails/new.jpeg')
          expect(updated_whereis_result['.derivs/thumbnails/new.jpeg'].locations.map(&:description)).to include '[local]'
          expect(updated_repo.thumbnail).to eql 'new.tif'
          expect(updated_repo.thumbnail_location).to eql "#{updated_repo.names.bucket}/#{updated_git.annex.lookupkey('.derivs/thumbnails/new.jpeg')}"
        end

        it 'updated descriptive metadata source' do
          metadata_source = updated_repo.descriptive_metadata
          expect(metadata_source.source_type).to eql 'descriptive'
          expect(metadata_source.original_mappings).to eql descriptive_metadata.merge(updated_descriptive_metadata)
          expect(metadata_source.user_defined_mappings).to eql descriptive_metadata.merge(updated_descriptive_metadata)
          expect(metadata_source.remote_location).to eql "#{updated_repo.names.bucket}/#{updated_git.annex.lookupkey('data/metadata/descriptive_metadata.csv')}"
        end

        it 'generated metadata files contain expected data' do
          updated_git.annex.get(updated_repo.metadata_subdirectory)
          expect(File.read(File.join(updated_working_dir, updated_repo.metadata_subdirectory, 'descriptive_metadata.csv'))).to eql updated_descriptive
          expect(File.read(File.join(updated_working_dir, updated_repo.metadata_subdirectory, 'structural_metadata.csv'))).to eql updated_structural
        end

        it 'updated structural metadata source' do
          metadata_source = updated_repo.structural_metadata
          expect(metadata_source.source_type).to eql 'structural'
          expect(metadata_source.original_mappings).to eql updated_structural_metadata
          expect(metadata_source.user_defined_mappings).to eql updated_structural_metadata
        end

        it 'contains updated generated metadata' do
          updated_git.annex.get(updated_repo.metadata_subdirectory)
          expect(Nokogiri::XML(File.read(File.join(updated_working_dir, updated_repo.metadata_subdirectory, 'mets.xml')))).to be_equivalent_to(updated_mets).ignoring_attr_values('OBJID').ignoring_content_of('mods|identifier')
          expect(Nokogiri::XML(File.read(File.join(updated_working_dir, updated_repo.metadata_subdirectory, 'preservation.xml')))).to be_equivalent_to(updated_preservation).ignoring_content_of('uuid')
        end
      end
    end

    context 'when creating a new digital object with one asset' do
      let(:descriptive_metadata) do
        { 'title' => ['Trade card; J. Rosenblatt & Co.; Baltimore, Maryland, United States; undated;'] }
      end
      let(:import) do
        described_class.new(
          type: Bulwark::Import::CREATE,
          directive: 'object_one',
          assets: { 'drive' => 'test', 'path' => 'object_one/front.tif' },
          descriptive_metadata: descriptive_metadata,
          structural_metadata: { 'filenames' => 'front.tif' },
          created_by: created_by
        )
      end
      let(:repo) { Repo.find_by(unique_identifier: result.unique_identifier) }
      let(:working_dir) { repo.version_control_agent.clone }
      let(:git) { ExtendedGit.open(working_dir) }
      let(:whereis_result) { git.annex.whereis }

      let(:result) { import.process }

      it 'contains assets file' do
        expect(whereis_result.map(&:filepath)).to include('data/assets/front.tif')
        expect(whereis_result['data/assets/front.tif'].locations.map(&:description)).to include '[local]'
      end

      it 'contains derivatives' do
        derivatives = ['.derivs/front.tif.jpeg', '.derivs/front.tif.thumb.jpeg']
        expect(whereis_result.map(&:filepath)).to include(*derivatives)
        derivatives.each do |filepath|
          expect(whereis_result[filepath].locations.map(&:description)).to include '[local]'
        end
      end
    end

    context 'when creating a new digital object with advanced structural metadata' do
      let(:structural_metadata) do
        {
          'sequence' => [
            { 'sequence' => '1', 'filename' => 'front.tif', 'label' => 'p. 1', 'viewing_direction' => 'top-to-bottom' },
            { 'sequence' => '2', 'filename' => 'back.tif', 'label' => 'p. 2', 'viewing_direction' => 'top-to-bottom' }
          ]
        }
      end
      let(:expected_structural) { fixture_to_str('example_manifest_loads', 'object_one', 'structural_metadata.csv') }
      let(:import) do
        described_class.new(
          type: Bulwark::Import::CREATE,
          directive: 'object_one',
          assets: { drive: 'test', path: 'object_one' },
          descriptive_metadata: { title: ['Object One'] },
          structural_metadata: { drive: 'test', path: 'object_one/structural_metadata.csv' },
          created_by: created_by
        )
      end
      let(:repo) { Repo.find_by(unique_identifier: result.unique_identifier) }
      let(:working_dir) { repo.version_control_agent.clone }
      let(:git) { ExtendedGit.open(working_dir) }
      let(:whereis_result) { git.annex.whereis }

      let(:result) { import.process }

      it 'import was successful' do
        expect(result.status).to be Bulwark::Import::Result::SUCCESS
      end

      it 'creates structural metadata source' do
        metadata_source = repo.structural_metadata
        expect(metadata_source.source_type).to eql 'structural'
        expect(metadata_source.original_mappings).to eql structural_metadata
        expect(metadata_source.user_defined_mappings).to eql structural_metadata
        expect(metadata_source.remote_location).to eql "#{repo.names.bucket}/#{git.annex.lookupkey('data/metadata/structural_metadata.csv')}"
      end

      it 'given structural metadata files contain expected data' do
        git.annex.get(repo.metadata_subdirectory)
        expect(File.read(File.join(working_dir, repo.metadata_subdirectory, 'structural_metadata.csv'))).to eql expected_structural
      end

      it 'generates expected images_to_render hash' do
        expect(repo.images_to_render).to match({
          'iiif' => {
            'images' => [
              "/#{repo.names.bucket}%2F#{git.annex.lookupkey('.derivs/front.tif.jpeg')}/info.json",
              "/#{repo.names.bucket}%2F#{git.annex.lookupkey('.derivs/back.tif.jpeg')}/info.json"
            ],
            'reading_direction' => 'top-to-bottom'
          }
        })
      end
    end

    # TODO: Once Marc mapping has been reviewed, these tests need to be revisited.
    context 'when creating a new digital object with metadata from Alma' do
      let(:bibnumber) { '9923478503503681' }
      let(:descriptive_metadata) do
        {
          'bibnumber' => [bibnumber],
          'identifier' => [
            'sts- n.r* n.n. di12 (3) 1598 (A)', '(OCoLC)ocm16660686', '(OCoLC)16660686', '2347850', '(PU)2347850-penndb-Voyager'
          ],
          'creator' => ['Ercker, Lazarus,'],
          'title' => [
            "Beschreibung aller fürnemisten Mineralischen Ertzt vnnd Berckwercksarten :",
            "wie dieselbigen vnd eine jede in Sonderheit jrer Natur vnd Eygenschafft nach, auff alle Metalla probirt, vnd im kleinen Fewr sollen versucht werden, mit Erklärung etlicher fürnemer nützlicher Schmeltzwerck im grossen Feuwer, auch Scheidung Goldts, Silbers, vnd anderer Metalln, sampt einem Bericht des Kupffer Saigerns, Messing brennens, vnd Salpeter Siedens, auch aller saltzigen Minerischen proben, vnd was denen allen anhengig : in fünff Bücher verfast, dessgleichen zuvorn niemals in Druck kommen ... : auffs newe an vielen Orten mit besserer Aussführung, vnd mehreren Figurn erklärt /",
            "durch den weitberühmten Lazarum Erckern, der Röm. Kay. May. Obersten Bergkmeister vnd Buchhalter in Königreich Böhem  ..."
          ],
          'publisher' => ["Gedruckt zu Franckfurt am Mayn : Durch Johan Feyerabendt, 1598."],
          'format' => ['[4], 134, [4] leaves : ill. ; 31 cm. (fol.)'],
          'bibliographic_note' => [
            'Leaves printed on both sides. Signatures: )(⁴ A-Z⁴ a-k⁴ l⁶. The last leaf is blank. Woodcut illustrations, initials and tail-pieces. Title page printed in black and red. Printed marginalia. "Erratum" on verso of last printed leaf. Online version available via Colenda https://colenda.library.upenn.edu/catalog/81431-p3df6k90j'
          ],
          'provenance' => ["Smith, Edgar Fahs, 1854-1928 (autograph, 1917)", "Wright, H. (autograph, 1870)"],
          'description' => ["Penn Libraries copy has Edgar Fahs Smith's autograph on front free endpaper; autograph of H. Wright on front free endpaper; effaced ms. inscription (autograph?) on title leaf."],
          'subject' => ['Metallurgy -- Early works to 1800.', 'Assaying -- Early works to 1800.', 'PU', 'PU', 'PU'],
          'date' => ['1598'],
          'personal_name' => ['Feyerabend, Johann,'],
          'geographic_subject' => ['Germany -- Frankfurt am Main.'],
          'collection' => ['Edgar Fahs Smith Memorial Collection (University of Pennsylvania)'],
          'display_call_number' => ['Folio TN664 .E7 1598'],
          'relation' => ['https://colenda.library.upenn.edu/catalog/81431-p3df6k90j'],
          'item_type' => ['Manuscript']
        }
      end
      let(:import) do
        described_class.new(
          type: Bulwark::Import::CREATE,
          directive: 'object_one',
          assets: { drive: 'test', path: 'object_one' },
          descriptive_metadata: { 'bibnumber' => [bibnumber], 'item_type' => ['Manuscript'] },
          structural_metadata: { 'filenames' => 'front.tif; back.tif' },
          created_by: created_by
        )
      end
      let(:expected_mets) { fixture_to_xml('example_objects', 'object_two', 'mets.xml') }
      let(:expected_preservation) { fixture_to_xml('example_objects', 'object_two', 'preservation.xml') }
      let(:expected_descriptive) { fixture_to_str('example_objects', 'object_two', 'descriptive_metadata.csv') }

      let(:repo) { Repo.find_by(unique_identifier: result.unique_identifier) }
      let(:working_dir) { repo.version_control_agent.clone }
      let(:git) { ExtendedGit.open(working_dir) }
      let(:whereis_result) { git.annex.whereis }

      let(:result) { import.process }

      # Stub marmite request
      before do
        stub_request(:get, "https://marmite.library.upenn.edu/#{bibnumber}/create?format=marc21")
          .to_return(status: 200, body: fixture_to_str('marmite', 'marc_xml', "#{bibnumber}.xml"), headers: {})
      end

      it 'creates descriptive metadata source' do
        metadata_source = repo.descriptive_metadata
        expect(metadata_source.source_type).to eql 'descriptive'
        expect(metadata_source.original_mappings).to eql({ 'bibnumber' => [bibnumber], 'item_type' => ['Manuscript'] })
        expect(metadata_source.user_defined_mappings).to eql descriptive_metadata
        expect(metadata_source.remote_location).to eql "#{repo.names.bucket}/#{git.annex.lookupkey('data/metadata/descriptive_metadata.csv')}"
      end

      it 'descriptive metadata csv contains expected data' do
        git.annex.get(repo.metadata_subdirectory)
        expect(File.read(File.join(working_dir, repo.metadata_subdirectory, 'descriptive_metadata.csv'))).to eql expected_descriptive
      end

      it 'generated metadata files contain expected data' do
        git.annex.get(repo.metadata_subdirectory)
        expect(Nokogiri::XML(File.read(File.join(working_dir, repo.metadata_subdirectory, 'preservation.xml')))).to be_equivalent_to(expected_preservation).ignoring_content_of('uuid')
        expect(Nokogiri::XML(File.read(File.join(working_dir, repo.metadata_subdirectory, 'mets.xml')))).to be_equivalent_to(expected_mets).ignoring_attr_values('OBJID').ignoring_content_of('mods|identifier')
      end
    end
  end
end
