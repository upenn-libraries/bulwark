require 'rails_helper'

RSpec.describe ReposController, type: :request do
  describe '#fetch_image_ids' do
    let(:repo) { FactoryBot.create(:repo) }

    before do
      ENV['IIIF_IMAGE_SERVER'] = 'https://colenda.library.upenn.edu/phalt/iiif/2/'
      # add images to render hash
      repo.images_to_render = {
        'iiif' => {
          'reading_direction' => 'left-to-right',
          'images' => [
            'https://colenda.library.upenn.edu/phalt/iiif/2//ark81431p3348gn33%2FSHA256E-s4031202--d312b4a5ef5cf37391e17f6378dcf0c84a06823d4136b2ca941c8102b2335a91.tif.jpeg/info.json',
            'https://colenda.library.upenn.edu/phalt/iiif/2//ark81431p3348gn33%2FSHA256E-s3777716--bd9ef5508f78c9bcc5bcb867c6533cea6f9bfcd37dc4e4ae398fef513c576c94.tif.jpeg/info.json'
          ]
        }
      }
      repo.save

      # add descriptive metadata
      MetadataSource.create(
        source_type: 'pqc',
        user_defined_mappings: { 'title' => ['Legal document; Charleston, South Carolina, United States; 1798 April 5'] },
        metadata_builder: repo.metadata_builder
      )
      repo.reload

      get "/repos/#{repo.names.fedora}/fetch_image_ids"
    end

    after do
      ENV['IIIF_IMAGE_SERVER'] = ''
    end

    it 'returns expected response' do
      expect(JSON.parse(response.body)).to eql(
        {
          'id' => repo.names.fedora,
          'title' => 'Legal document; Charleston, South Carolina, United States; 1798 April 5',
          'reading_direction' => 'left-to-right',
          'image_ids' => [
            '/ark81431p3348gn33%2FSHA256E-s4031202--d312b4a5ef5cf37391e17f6378dcf0c84a06823d4136b2ca941c8102b2335a91.tif.jpeg',
            '/ark81431p3348gn33%2FSHA256E-s3777716--bd9ef5508f78c9bcc5bcb867c6533cea6f9bfcd37dc4e4ae398fef513c576c94.tif.jpeg'
          ]
        }
      )
    end
  end
end
