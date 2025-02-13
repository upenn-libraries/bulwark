# frozen_string_literal: true

RSpec.describe 'Item Endpoints', type: :request do
  # POST /items
  context 'when adding a item' do
    let(:headers) do
      { 'Content-Type' => 'application/json',
        'Authorization' => "Token token=#{Settings.publishing_endpoint.token}" }
    end

    before { post items_path, { item: params }.to_json, headers }

    context 'with invalid token' do
      let(:headers) { {} }
      let(:params) { {} }

      it 'returns 401' do
        expect(response).to have_http_status :unauthorized
      end
    end

    context 'with a payload with iiif assets' do
      let(:params) do
        {
          id: 'ark:/99999/fk4pp0qk3c',
          first_published_at: '2023-01-03T14:27:35Z',
          last_published_at: '2024-01-03T11:22:30Z',
          uuid: '36a224db-c416-4769-9da1-28513827d179',
          descriptive_metadata: {
            title: [{ value: 'Message from Phanias and others of the agoranomoi of Oxyrhynchus about a purchase of land.' }],
            collection: [{ value: 'University of Pennsylvania Papyrological Collection' }]
          },
          thumbnail_asset_id: 'b65d33d3-8c34-4e36-acf9-dab273277583',
          iiif_manifest_path: '36a224db-c416-4769-9da1-28513827d179/iiif_manifest',
          assets: [
            {
              id: 'b65d33d3-8c34-4e36-acf9-dab273277583',
              filename: 'e2750_wk1_body0001.tif',
              iiif: true,
              original_file: {
                path: 'b65d33d3-8c34-4e36-acf9-dab273277583/df4f0a9b-e657-41fb-82b7-228cc9a0642b',
                size: '',
                mime_type: 'image/tiff'
              }
            }
          ]
        }
      end

      it 'returns 200' do
        expect(response).to have_http_status 200
      end

      it 'adds document to Solr' do
        solr = RSolr.connect(url: Settings.solr.url)
        response = solr.get('select', params: { q: "unique_identifier_ssi:\"#{params[:id]}\"" })
        expect(response['response']['numFound']).to be 1
      end

      it 'adds a database record' do
        expect(Item.find_by(unique_identifier: params[:id])).to be_present
      end
    end

    context 'when missing required keys' do
      let(:params) do
        {
          id: 'ark:/99999/fk4pp0qk3c',
          first_published_at: '2023-01-03T14:27:35Z',
          last_published_at: '2024-01-03T11:22:30Z'
        }
      end

      it 'returns 400' do
        expect(response).to have_http_status 400
      end

      it 'does not create a database record' do
        expect(Item.count).to be 0
      end

      it 'does not add document to Solr' do
        solr = RSolr.connect(url: Settings.solr.url)
        response = solr.get('select', params: { q: '*:*' })
        expect(response['response']['numFound']).to be 0
      end
    end
  end

  # DELETE /items/:id
  context 'when deleting an item' do
    let(:headers) do
      { 'Content-Type' => 'application/json',
        'Authorization' => "Token token=#{Settings.publishing_endpoint.token}" }
    end

    context 'with invalid token' do
      let(:headers) { {} }
      let(:id) { 'ark:/12345/sample' }

      before do
        delete "/items/#{id}", {}, headers
      end

      it 'returns 401' do
        expect(response).to have_http_status :unauthorized
      end
    end

    context 'when item not present' do
      let(:id) { 'ark:/12345/invalid' }

      before do
        delete "/items/#{id}", {}, headers
      end

      it 'return 404' do
        expect(response).to have_http_status 404
      end
    end

    context 'when item is present' do
      let(:id) { 'ark:/99999/fk4pp0qk3c' }
      let(:json) do
        {
          id: id,
          first_published_at: '2023-01-03T14:27:35Z',
          last_published_at: '2024-01-03T11:22:30Z',
          uuid: '36a224db-c416-4769-9da1-28513827d179'
        }
      end

      before do
        Item.create(unique_identifier: id, published_json: json)
        delete "/items/#{id}", {}, headers
      end

      it 'return 204' do
        expect(response).to have_http_status :no_content
      end

      it 'deletes record from Solr' do
        solr = RSolr.connect(url: Settings.solr.url)
        response = solr.get('select', params: { q: "unique_identifier_ssi:\"#{id}\"" })
        expect(response['response']['numFound']).to be 0
      end

      it 'deletes record from database' do
        expect(Item.find_by(unique_identifier: id)).to be_nil
      end
    end
  end

  # GET /items/:item_id/thumbnail
  context 'when fetching thumbnail file' do
    before { get "/items/#{unique_identifier}/thumbnail" }

    context 'when item_id invalid' do
      let(:unique_identifier) { 'ark:/12345/invalid' }

      it 'returns 404' do
        expect(response).to have_http_status 404
      end
    end

    context 'when item_id is valid' do
      let(:unique_identifier) { item.unique_identifier }

      context 'when thumbnail available' do
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

  # GET /items/:id/manifest
  context 'when fetching iiif manifest' do
    before { item.add_solr_document! if defined?(item) }

    context 'when id valid and iiif manifest present' do
      let(:item) { FactoryBot.create(:item, :with_image) }
      let(:unique_identifier) { item.unique_identifier }

      before do
        client = instance_double('Aws::S3::Client')
        io = instance_double('IO', read: 'sample_data')
        response = instance_double('Aws::S3::Types::GetObjectOutput', body: io)
        allow(Aws::S3::Client).to receive(:new).with(any_args).and_return(client)
        allow(client).to receive(:get_object).with(bucket: 'iiif-manifests-dev', key: '36a224db-c416-4769-9da1-28513827d179/iiif_manifest')
                                             .and_return(response)

        get "/items/#{unique_identifier}/manifest"
      end

      it 'sends data' do
        expect(response.body).to eq 'sample_data'
      end

      it 'has correct CORS header' do
        expect(response.headers).to include 'Access-Control-Allow-Origin' => '*'
      end
    end

    context 'when id invalid' do
      let(:unique_identifier) { 'ark:/12345/invalid' }

      before { get "/items/#{unique_identifier}/manifest" }

      it 'returns 404' do
        expect(response).to have_http_status 404
      end
    end

    context 'when iiif manifest not present' do
      let(:item) { FactoryBot.create(:item) }
      let(:unique_identifier) { item.unique_identifier }

      before { get "/items/#{unique_identifier}/manifest" }

      it 'returns 404' do
        expect(response).to have_http_status 404
      end
    end
  end
end
