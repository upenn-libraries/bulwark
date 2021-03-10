# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Bulwark::Migrate do
  describe '.validate' do
    context 'when action is not valid' do
      subject(:migration) { described_class.new(action: 'invalid') }
      it 'adds error' do
        expect(migration.validate).to be false
        expect(migration.errors).to include '"invalid" is not a valid migration action'
      end
    end

    context 'when migrated_by is missing' do
      subject(:migration) { described_class.new(action: 'migrate') }

      it 'adds error' do
        expect(migration.validate).to be false
        expect(migration.errors).to include 'Missing migrated_by'
      end
    end

    context 'when new structural metadata is not present' do
      subject(:migration) { described_class.new(action: 'migrate') }

      it 'adds error' do
        expect(migration.validate).to be false
        expect(migration.errors).to include 'Missing structural metadata'
      end
    end

    context 'when new descriptive metadata is not present' do
      subject(:migration) { described_class.new(action: 'migrate') }

      it 'adds error' do
        expect(migration.validate).to be false
        expect(migration.errors).to include 'Missing metadata'
      end
    end

    context 'when unique_identifier is missing' do
      subject(:migration) { described_class.new(action: 'migrate') }

      it 'adds error' do
        expect(migration.validate).to be false
        expect(migration.errors).to include 'Missing unique_identifier'
      end
    end

    context 'when Repo could not be found' do
      subject(:migration) { described_class.new(action: 'migrate', unique_identifier: 'ark:/99999/not_valid') }

      it 'adds error' do
        expect(migration.validate).to be false
        expect(migration.errors).to include 'Repo could not be found'
      end
    end

    context 'when Repo\'s ingested flag is false' do
      include_context 'stub successful EZID requests'

      subject(:migration) { described_class.new(action: 'migrate', unique_identifier: repo.unique_identifier) }
      let(:repo) { FactoryBot.create(:repo) }

      it 'adds error' do
        expect(migration.validate).to be false
        expect(migration.errors).to include 'Repo has not been ingested'
      end
    end

    context 'when Repo has invalid file_extension configured' do
      include_context 'stub successful EZID requests'

      subject(:migration) { described_class.new(action: 'migrate', unique_identifier: repo.unique_identifier) }
      let(:repo) { FactoryBot.create(:repo, file_extensions: ['sh']) }

      it 'adds error' do
        expect(migration.validate).to be false
        expect(migration.errors).to include 'Invalid file extensions present in model: sh'
      end
    end

    context 'when Repo does not have a valid solr record' do
      include_context 'stub successful EZID requests'

      subject(:migration) { described_class.new(action: 'migrate', unique_identifier: repo.unique_identifier) }
      let(:repo) { FactoryBot.create(:repo) }

      it 'adds error' do
        expect(migration.validate).to be false
        expect(migration.errors).to include 'Solr document for this object is not present'
      end
    end

    context 'when Repo has more than two metadata sources' do
      include_context 'stub successful EZID requests'

      subject(:migration) { described_class.new(action: 'migrate', unique_identifier: repo.unique_identifier) }
      let(:repo) { FactoryBot.create(:repo) }

      before do
        MetadataSource.create(source_type: 'kaplan', metadata_builder: repo.metadata_builder)
        MetadataSource.create(source_type: 'kaplan_structural', metadata_builder: repo.metadata_builder)
        MetadataSource.create(source_type: 'voyager', metadata_builder: repo.metadata_builder)
      end

      it 'adds error' do
        expect(migration.validate).to be false
        expect(migration.errors).to include 'Repo has more than two metadata sources'
      end
    end

    context 'when Repo does not have kaplan_structural MetadataSource' do
      include_context 'stub successful EZID requests'

      subject(:migration) { described_class.new(action: 'migrate', unique_identifier: repo.unique_identifier) }
      let(:repo) { FactoryBot.create(:repo) }

      before do
        MetadataSource.create(source_type: 'kaplan', metadata_builder: repo.metadata_builder)
        MetadataSource.create(source_type: 'voyager', metadata_builder: repo.metadata_builder)
      end

      it 'adds error' do
        expect(migration.validate).to be false
        expect(migration.errors).to include 'Metadata sources does not include kaplan_structural'
      end
    end

    context 'when Repo does not have kaplan MetadataSource' do
      include_context 'stub successful EZID requests'

      subject(:migration) { described_class.new(action: 'migrate', unique_identifier: repo.unique_identifier) }
      let(:repo) { FactoryBot.create(:repo) }

      before do
        MetadataSource.create(source_type: 'kaplan_structural', metadata_builder: repo.metadata_builder)
        MetadataSource.create(source_type: 'voyager', metadata_builder: repo.metadata_builder)
      end

      it 'adds error' do
        expect(migration.validate).to be false
        expect(migration.errors).to include 'Metadata sources does not include kaplan'
      end
    end

    context 'when User record cannot be found for owner' do
      include_context 'stub successful EZID requests'

      subject(:migration) { described_class.new(action: 'migrate', unique_identifier: repo.unique_identifier) }
      let(:repo) { FactoryBot.create(:repo, owner: 'new@example.com') }

      it 'adds error' do
        expect(migration.validate).to be false
        expect(migration.errors).to include 'Cannot retrieve User record for owner'
      end
    end

    context 'when Repo\'s metadata subdirectory is something other than data/metadata' do
      include_context 'stub successful EZID requests'

      subject(:migration) { described_class.new(action: 'migrate', unique_identifier: repo.unique_identifier) }
      let(:repo) { FactoryBot.create(:repo, metadata_subdirectory: 'data/data/metadata') }

      it 'adds error' do
        expect(migration.validate).to be false
        expect(migration.errors).to include 'Metadata subdirectory is not \'data/metadata\''
      end
    end
  end

  describe '.process' do
    include_context 'stub successful EZID requests'

    let(:migrated_by) { 'test@example.com' }

    before do
      User.create!(email: migrated_by, password: 'password')
    end

    context 'when items were loaded in "Kaplan-style"' do
      include_context 'manifest csv for object one'
      include_context 'cleanup test storage'

      # Loading an object with the old kaplan-style ingest process
      before do
        # Create object through Kaplan manifest load.
        AutomatedWorkflows::Kaplan::Csv.generate_repos(csv_filepath)
        AutomatedWorkflows::Agent.new(
          AutomatedWorkflows::Kaplan,
          [ark],
          AutomatedWorkflows::Kaplan::Csv.config.endpoint('test'),
          steps_to_skip: ['ingest']
        ).proceed

        # Ingest item to Fedora and Solr.
        AutomatedWorkflows::Agent.new(
          AutomatedWorkflows::IngestOnly,
          [ark],
          '',
          steps_to_skip: AutomatedWorkflows.config[:ingest_only][:steps_to_skip]
        ).proceed
      end

      context 'when object contains files that have the same name, but different file extensions' do
        before do
          repo = Repo.find_by(unique_identifier: ark)
          clone_location = repo.clone_location
          new_filepath = File.join(clone_location, repo.assets_subdirectory, 'front.txt')
          File.write(new_filepath, 'New Blank File')
          git = ExtendedGit.open(clone_location)
          git.add('.')
          git.commit("Adding new file")
          git.push('origin', 'master')
          git.push('origin', 'git-annex')
          git.annex.sync(content: true)
          repo.delete_clone
        end

        let(:migration_result) do
          described_class.new(
            action: 'migrate',
            unique_identifier: ark,
            structural: { filenames: 'front.tif; back.tif' },
            metadata: { title: ['A new item'] },
            migrated_by: User.find_by(email: migrated_by)
          ).process
        end

        it 'returns error' do
          expect(migration_result.status).to be DigitalObjectImport::FAILED
          expect(migration_result.errors).to include 'There are assets that share the same name but different extension'
        end
      end

      context 'when assets have an invalid file extension' do
        before do
          repo = Repo.find_by(unique_identifier: ark)
          clone_location = repo.clone_location
          new_filepath = File.join(clone_location, repo.assets_subdirectory, 'new.txt')
          File.write(new_filepath, 'New Blank File')
          git = ExtendedGit.open(clone_location)
          git.add('.')
          git.commit("Adding new file")
          git.push('origin', 'master')
          git.push('origin', 'git-annex')
          git.annex.sync(content: true)
          repo.delete_clone
        end

        let(:migration_result) do
          described_class.new(
            action: 'migrate',
            unique_identifier: ark,
            structural: { filenames: 'front.tif; back.tif' },
            metadata: { title: ['A new item'] },
            migrated_by: User.find_by(email: migrated_by)
          ).process
        end

        it 'returns error' do
          expect(migration_result.status).to be DigitalObjectImport::FAILED
          expect(migration_result.errors).to match_array ['Assets in git repo contain invalid file extensions: txt']
        end
      end

      context 'when contains invalid filenames in structural.filenames' do
        let(:migration_result) do
          described_class.new(
            action: 'migrate',
            unique_identifier: ark,
            structural: { filenames: 'front.tif; incorrect.tif' },
            metadata: { title: ['A new item'] },
            migrated_by: User.find_by(email: migrated_by)
          ).process
        end

        it 'returns error' do
          expect(migration_result.status).to be DigitalObjectImport::FAILED
          expect(migration_result.errors).to match_array ['Structural metadata contains the following invalid filenames: incorrect.tif']
        end
      end

      context 'when migrating object' do
        let(:structural_metadata) do
          {
            'sequence' => [
              { 'sequence' => '1', 'filename' => 'front.tif' },
              { 'sequence' => '2', 'filename' => 'back.tif' }
            ]
          }
        end

        let(:descriptive_metadata) do
          {
            'collection' => ['Arnold and Deanne Kaplan Collection of Early American Judaica (University of Pennsylvania)'],
            'call_number' => ['Arc.MS.56'],
            'item_type' => ['Trade cards'],
            'language' => ['English'],
            'date' => ['undated'],
            'corporate_name' => ['J. Rosenblatt & Co.'],
            'geographic_subject' => ['Baltimore, Maryland, United States', 'Maryland, United States'],
            'description' => ['J. Rosenblatt & Co.: Importers: Earthenware, China, Majolica, Novelties', '32 South Howard Street, Baltimore, MD'],
            'rights' => ['http://rightsstatements.org/page/NoC-US/1.0/?'],
            'subject' => ['House furnishings', 'Jewish merchants', 'Trade cards (advertising)'],
            'title' => ['Trade card; J. Rosenblatt & Co.; Baltimore, Maryland, United States; undated;']
          }
        end

        let(:expected_mets) { fixture_to_xml('example_objects', 'object_one', 'mets.xml') }
        let(:expected_preservation) { fixture_to_xml('example_objects', 'object_one', 'preservation.xml') }
        let(:expected_structural) { fixture_to_str('example_objects', 'object_one', 'structural_metadata.csv') }
        let(:expected_descriptive) { fixture_to_str('example_objects', 'object_one', 'descriptive_metadata.csv') }

        let(:migration_result) do
          described_class.new(
            action: 'migrate',
            unique_identifier: ark,
            structural: { filenames: 'front.tif; back.tif' },
            metadata: descriptive_metadata,
            migrated_by: User.find_by(email: migrated_by)
          ).process
        end
        let(:repo) { migration_result.repo }
        let(:working_dir) { repo.clone_location }
        let(:git) { ExtendedGit.open(working_dir) }

        it 'expect migration to be successful' do
          expect(migration_result.errors).to be_empty
          expect(migration_result.status).to be DigitalObjectImport::SUCCESSFUL
        end

        it 'contains two metadata sources' do
          expect(repo.metadata_builder.metadata_source.count).to be 2
        end

        it 'contains descriptive metadata source' do
          metadata_source = repo.descriptive_metadata
          expect(metadata_source.source_type).to eql 'descriptive'
          expect(metadata_source.original_mappings).to eql descriptive_metadata
          expect(metadata_source.user_defined_mappings).to eql descriptive_metadata
          expect(metadata_source.remote_location).to eql "#{repo.names.bucket}/#{git.annex.lookupkey('data/metadata/descriptive_metadata.csv')}"
        end

        it 'contains structural metadata source' do
          metadata_source = repo.structural_metadata
          expect(metadata_source.source_type).to eql 'structural'
          expect(metadata_source.original_mappings).to eql structural_metadata
          expect(metadata_source.user_defined_mappings).to eql structural_metadata
          expect(metadata_source.remote_location).to eql "#{repo.names.bucket}/#{git.annex.lookupkey('data/metadata/structural_metadata.csv')}"
        end

        it 'does not contain any endpoints' do
          expect(repo.endpoint).to be_blank
        end

        it 'has first_published_at date that matches created_at' do
          expect(repo.first_published_at).to eql repo.created_at
        end

        it 'has created_at user that matches owner' do
          expect(repo.created_by.email).to eql repo.owner
        end

        it 'has set updated_by to migrated_by value' do
          expect(repo.updated_by.email).to eql migrated_by
        end

        it 'contains expected asset db records' do
          front = repo.assets.find_by(filename: 'front.tif')
          back = repo.assets.find_by(filename: 'back.tif')

          expect(front).not_to be_nil
          expect(front.size).to be 42_421
          expect(front.mime_type).to eql 'image/jpeg'
          expect(front.original_file_location).to eql git.annex.lookupkey('data/assets/front.tif')
          expect(front.access_file_location).to eql git.annex.lookupkey('.derivs/access/front.jpeg')
          expect(front.thumbnail_file_location).to eql git.annex.lookupkey('.derivs/thumbnails/front.jpeg')

          expect(back).not_to be_nil
          expect(back.size).to be 33_079
          expect(back.mime_type).to eql 'image/jpeg'
          expect(back.original_file_location).to eql git.annex.lookupkey('data/assets/back.tif')
          expect(back.access_file_location).to eql git.annex.lookupkey('.derivs/access/back.jpeg')
          expect(back.thumbnail_file_location).to eql git.annex.lookupkey('.derivs/thumbnails/back.jpeg')
        end

        it 'contains expected assets' do
          whereis_result = git.annex.whereis(repo.assets_subdirectory)
          expect(whereis_result.map(&:filepath)).to match_array ['data/assets/back.tif', 'data/assets/front.tif']
          expect(whereis_result['data/assets/back.tif'].locations.map(&:description)).to include '[local]'
          expect(whereis_result['data/assets/front.tif'].locations.map(&:description)).to include '[local]'
        end

        it 'contains expected generated derivatives (does not contain previously created derivatives)' do
          whereis_result = git.annex.whereis(repo.derivatives_subdirectory)
          derivatives = ['.derivs/access/back.jpeg', '.derivs/thumbnails/back.jpeg', '.derivs/access/front.jpeg', '.derivs/thumbnails/front.jpeg']
          expect(whereis_result.map(&:filepath)).to match_array derivatives
          derivatives.each do |filepath|
            expect(whereis_result[filepath].locations.map(&:description)).to include '[local]'
          end
        end

        # Check metadata files exists and have correct contents
        it 'contains expected metadata contents for preservation.xml, mets.xml, descriptive_metadata.csv, and structural_metadata.csv' do
          git.annex.get(repo.metadata_subdirectory)
          expect(File.read(File.join(working_dir, repo.metadata_subdirectory, 'structural_metadata.csv'))).to eql expected_structural
          expect(File.read(File.join(working_dir, repo.metadata_subdirectory, 'descriptive_metadata.csv'))).to eql expected_descriptive
          expect(
            Nokogiri::XML(File.read(File.join(working_dir, repo.metadata_subdirectory, 'preservation.xml')))
          ).to be_equivalent_to(expected_preservation).ignoring_content_of('uuid')
          expect(
            Nokogiri::XML(File.read(File.join(working_dir, repo.metadata_subdirectory, 'mets.xml')))
          ).to be_equivalent_to(expected_mets).ignoring_attr_values('OBJID').ignoring_content_of('mods|identifier')
        end

        it 'contains jhove output for assets' do
          jhove_output_relative_path = File.join(repo.metadata_subdirectory, 'jhove_output.xml')
          git.annex.get(jhove_output_relative_path)
          expect(
            Bulwark::JhoveOutput.new(File.join(working_dir, jhove_output_relative_path)).filenames
          ).to match_array [".keep", "back.tif", "front.tif"]
        end

        it 'contains extracted metadata files' do
          whereis_result = git.annex.whereis(repo.metadata_subdirectory)
          metadata_filepaths = [
            'data/metadata/jhove_output.xml', 'data/metadata/preservation.xml', 'data/metadata/mets.xml',
            'data/metadata/descriptive_metadata.csv', 'data/metadata/structural_metadata.csv'
          ]
          expect(whereis_result.map(&:filepath)).to match_array(metadata_filepaths)
        end

        it 'publishes record' do
          expect(repo.published).to be true
          expect(repo.last_published_at).not_to be_blank
          expect(Blacklight.default_index.search(q: "id:#{repo.names.fedora}", fl: 'id').docs.count).to be 1
        end

        it 'cleans up db records' do
          expect(repo.file_display_attributes).to be_blank
          expect(repo.images_to_render).to be_blank
          expect(repo.new_format).to be true
          expect(repo.metadata_builder.xml_preview).to be_blank
          expect(repo.metadata_builder.preserve).to be_blank
        end
      end
    end
  end
end
