# frozen_string_literal: true

RSpec.describe 'Asset Endpoints', type: :request do
  # GET /items/:item_id/assets/:id/thumbnail
  context 'when fetching thumbnail file' do
    before { get "/items/#{unique_identifier}/assets/12345/thumbnail" }

    context 'when item_id invalid' do
      let(:unique_identifier) { 'ark:/12345/invalid' }

      it 'returns 404' do
        expect(response).to have_http_status 404
      end
    end

    context 'when item_id is valid' do
      let(:item) { FactoryBot.create(:item) }
      let(:unique_identifier) { item.unique_identifier }

      it 'redirects to presigned URL' do
        expect(request).to redirect_to %r{\Ahttp://minio-dev.library.upenn.edu/derivatives-dev/12345/thumbnail}
      end
    end
  end

  # GET /items/:item_id/assets/:id/access
  context 'when fetching access file' do
    before { get "/items/#{unique_identifier}/assets/#{asset_id}/access" }

    context 'when item_id invalid' do
      let(:unique_identifier) { 'ark:/12345/invalid' }
      let(:asset_id) { '12345' }

      it 'returns 404' do
        expect(response).to have_http_status 404
      end
    end

    context 'when item_id is valid' do
      let(:item) { FactoryBot.create(:item, :with_asset) }
      let(:unique_identifier) { item.unique_identifier }
      let(:asset_id) { 'b65d33d3-8c34-4e36-acf9-dab273277583' }

      it 'redirects to presigned URL with correct filename' do
        expect(request).to redirect_to %r{\Ahttp://minio-dev.library.upenn.edu/derivatives-dev/b65d33d3-8c34-4e36-acf9-dab273277583/access}
        expect(request).to redirect_to %r{e2750_wk1_body0001.jpeg}
      end
    end
  end

  # GET /items/:item_id/assets/:id/original
  context 'when fetching original file' do
    before { get "/items/#{unique_identifier}/assets/#{asset_id}/original" }

    context 'when item_id invalid' do
      let(:unique_identifier) { 'ark:/12345/invalid' }
      let(:asset_id) { '12345' }

      it 'returns 404' do
        expect(response).to have_http_status 404
      end
    end

    context 'when original file not present in json data' do
      let(:item) { FactoryBot.create(:item) }
      let(:unique_identifier) { item.unique_identifier }
      let(:asset_id) { '12345' }

      it 'returns 404' do
        expect(response).to have_http_status 404
      end
    end

    context 'when original file present in json data' do
      let(:item) { FactoryBot.create(:item, :with_asset) }
      let(:unique_identifier) { item.unique_identifier }
      let(:asset_id) { 'b65d33d3-8c34-4e36-acf9-dab273277583' }

      it 'redirects to presigned URL' do
        expect(request).to redirect_to %r{\Ahttp://minio-dev.library.upenn.edu/preservation-dev/b65d33d3-8c34-4e36-acf9-dab273277583/df4f0a9b-e657-41fb-82b7-228cc9a0642b}
      end
    end
  end
end
