require 'rails_helper'

RSpec.describe AutomatedWorkflows::Agent do

  describe '.new'

  describe '#proceed' do
    context 'when creating an item first time' do
      include_context 'manifest csv for object one'
      include_context 'cleanup test storage' # TODO: Can remove this once Repos cleanup after themselves.

      let(:agent) do
        AutomatedWorkflows::Agent.new(
          AutomatedWorkflows::Kaplan,
          [ark],
          AutomatedWorkflows::Kaplan::Csv.config.endpoint('test'),
          steps_to_skip: ['ingest']
        )
      end
      let(:repo) { Repo.find_by(unique_identifier: ark) }

      before do
        AutomatedWorkflows::Kaplan::Csv.generate_repos(csv_filepath)
        agent.proceed
      end

      context 'when cloaning repo' do
        let(:working_dir) {repo.version_control_agent.clone}
        let(:git) { ExtendedGit.open(working_dir) }
        let(:whereis_result) { git.annex.whereis }

        it 'contains assets files' do
          expect(whereis_result.map(&:filepath)).to include('data/assets/back.tif', 'data/assets/front.tif')
          expect(whereis_result['data/assets/back.tif'].locations.map(&:description)).to include '[local]'
          expect(whereis_result['data/assets/front.tif'].locations.map(&:description)).to include '[local]'
        end

        it 'contains metadata files' do
          expect(whereis_result.map(&:filepath)).to include('data/metadata/metadata.xlsx', 'data/metadata/mets.xml', 'data/metadata/preservation.xml')
          expect(whereis_result['data/metadata/metadata.xlsx'].locations.map(&:description)).to include '[local]'
          expect(whereis_result['data/metadata/mets.xml'].locations.map(&:description)).to include '[local]'
          expect(whereis_result['data/metadata/preservation.xml'].locations.map(&:description)).to include '[local]'

        end

        it 'contains derivatives' do
          derivatives = ['.derivs/back.tif.jpeg', '.derivs/back.tif.thumb.jpeg', '.derivs/front.tif.jpeg', '.derivs/front.tif.thumb.jpeg']
          expect(whereis_result.map(&:filepath)).to include('.derivs/back.tif.jpeg', '.derivs/back.tif.thumb.jpeg', '.derivs/front.tif.jpeg', '.derivs/front.tif.thumb.jpeg')
          derivatives.each do |filepath|
            expect(whereis_result[filepath].locations.map(&:description)).to include '[local]'
          end
        end

        it 'contains .keep files only added via git' do
          expect(
            whereis_result.map(&:filepath).keep_if { |path| File.basename(path) == '.keep' }
          ).to be_empty
        end
      end

      it 'generates expected images_to_render hash' do
        expect(repo.images_to_render).to match({
          'iiif' => {
            'images' => [
              "/#{repo.names.bucket}%2FSHA256E-s543526--c39499899465124b36b9d4ea0dca99e5aa150dc6f2532598f5626aa2712f571a.tif.jpeg/info.json",
              "/#{repo.names.bucket}%2FSHA256E-s450792--9e90bce3272fcea22c84195ebd9391fcc8672da969fc08f55b99112c25fdef6b.tif.jpeg/info.json"
            ],
            'reading_direction' => 'left-to-right'
          }
        })
      end

      it 'generates expected metadata sources objects' do
        descriptive_metadata = repo.metadata_builder.metadata_source.find_by(path: 'data/metadata/metadata.xlsx')
        expect(descriptive_metadata.original_mappings).to include(
          'Filename(s)' => ['front.tif; back.tif'],
          'Title' => ['Trade card; J. Rosenblatt & Co.; Baltimore, Maryland, United States; undated;']
        )
      end

      context 'when ingesting content' do
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
          expect(fedora_object.unique_identifier).to eql ark
          expect(fedora_object.thumbnail).to be_a ActiveFedora::File
        end

        it 'creates solr document' do
          document = Blacklight.default_index.find(repo.names.fedora).docs.first
          expect(document['active_fedora_model_ssi']).to eql 'PrintedWork'
          expect(document['title_ssim']).to match_array('Trade card; J. Rosenblatt &amp; Co.; Baltimore, Maryland, United States; undated;')
          expect(document['unique_identifier_tesim']).to match_array(ark)
        end
      end
    end

    context 'when updating a digital object with a new asset'
  end
end
