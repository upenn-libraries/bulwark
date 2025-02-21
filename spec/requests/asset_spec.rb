# frozen_string_literal: true

RSpec.describe 'Asset Endpoints', type: :request do
  # GET /items/:item_id/assets/:id/thumbnail
  context 'when fetching thumbnail file' do
    before { get "/items/#{unique_identifier}/assets/#{asset_id}/thumbnail" }

    context 'when item_id invalid' do
      let(:unique_identifier) { 'ark:/12345/invalid' }
      let(:asset_id) { '12345' }

      it 'returns 404' do
        expect(response).to have_http_status 404
      end
    end

    context 'when item_id is valid' do
      let(:unique_identifier) { item.unique_identifier }
      let(:asset_id) { 'b65d33d3-8c34-4e36-acf9-dab273277583' }

      context 'when thumbnail is available' do
        let(:item) { FactoryBot.create(:item, :with_image) }

        it 'redirects to presigned URL' do
          expect(request).to redirect_to %r{\Ahttp://minio-dev.library.upenn.edu/derivatives-dev/b65d33d3-8c34-4e36-acf9-dab273277583/thumbnail}
        end
      end

      context 'when thumbnail unavailable' do
        let(:item) { FactoryBot.create(:item, :with_pdf) }

        it 'returns 404' do
          expect(response).to have_http_status 404
        end
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
      let(:unique_identifier) { item.unique_identifier }
      let(:asset_id) { 'b65d33d3-8c34-4e36-acf9-dab273277583' }

      context 'when access copy available' do
        let(:item) { FactoryBot.create(:item, :with_video) }

        it 'redirects to presigned URL with correct filename' do
          expect(request).to redirect_to %r{\Ahttp://minio-dev.library.upenn.edu/derivatives-dev/b65d33d3-8c34-4e36-acf9-dab273277583/access}
          expect(request).to redirect_to %r{e2750_wk1_vid0001.mp4}
        end
      end

      context 'when access copy unavailable' do
        let(:item) { FactoryBot.create(:item, :with_pdf) }

        it 'returns 404' do
          expect(response).to have_http_status 404
        end
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
      let(:item) { FactoryBot.create(:item, :with_image) }
      let(:unique_identifier) { item.unique_identifier }
      let(:asset_id) { 'b65d33d3-8c34-4e36-acf9-dab273277583' }

      it 'redirects to presigned URL' do
        expect(request).to redirect_to %r{\Ahttp://minio-dev.library.upenn.edu/preservation-dev/b65d33d3-8c34-4e36-acf9-dab273277583/df4f0a9b-e657-41fb-82b7-228cc9a0642b}
      end
    end
  end
end
