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
          steps_to_skip: ['xml', 'ingest']
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
          expect(whereis_result.map(&:filepath)).to include('data/metadata/metadata.xlsx')
          expect(whereis_result['data/metadata/metadata.xlsx'].locations.map(&:description)).to include '[local]'
        end

        it 'contains derivatives' do
          derivatives = ['.derivs/back.tif.jpeg', '.derivs/back.tif.thumb.jpeg', '.derivs/front.tif.jpeg', '.derivs/front.tif.thumb.jpeg']
          expect(whereis_result.map(&:filepath)).to include('.derivs/back.tif.jpeg', '.derivs/back.tif.thumb.jpeg', '.derivs/front.tif.jpeg', '.derivs/front.tif.thumb.jpeg')
          derivatives.each do |filepath|
            expect(whereis_result[filepath].locations.map(&:description)).to include '[local]'
          end
        end
      end

      it 'generates expected images_to_render hash' do
        expect(repo.images_to_render).to match({
          'iiif' => {
            'images' => [
              '/ark99999fk4th9vh1c%2FSHA256E-s543526--c39499899465124b36b9d4ea0dca99e5aa150dc6f2532598f5626aa2712f571a.tif.jpeg/info.json',
              '/ark99999fk4th9vh1c%2FSHA256E-s450792--9e90bce3272fcea22c84195ebd9391fcc8672da969fc08f55b99112c25fdef6b.tif.jpeg/info.json'
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
    end

    context 'when updating a digital object with a new asset'
  end
end
