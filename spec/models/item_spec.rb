# frozen_string_literal: true

RSpec.describe Item, type: :model do
  describe '#valid?' do
    context 'when unique_identifier is not unique' do
      let(:unique_identifier) { 'ark:/12345/12345' }
      let(:base_json) do
        { id: unique_identifier, uuid: '1234',
          first_published_at: '2023-01-03T14:27:35Z', last_published_at: '2023-01-03T14:27:35Z' }
      end
      let(:item) { Item.new(unique_identifier: unique_identifier, published_json: base_json) }

      before { Item.create(unique_identifier: unique_identifier, published_json: base_json) }

      it 'adds correct error' do
        expect(item.valid?).to be false
        expect(item.errors.messages[:unique_identifier]).to include 'has already been taken'
      end
    end

    context 'when published_json is not present' do
      let(:item) { Item.new(unique_identifier: 'ark:/12345/abcdefg', published_json: {}) }

      it 'adds correct error' do
        expect(item.valid?).to be false
        expect(item.errors.messages[:published_json]).to include 'can\'t be blank'
      end
    end

    context 'when unique_identifier is not present' do
      let(:item) { Item.new(unique_identifier: nil) }

      it 'adds correct error' do
        expect(item.valid?).to be false
        expect(item.errors.messages[:unique_identifier]).to include 'can\'t be blank'
      end
    end

    context 'when keys are missing from published json'
  end

  describe '#solr_document' do
    let(:item) { Item.new(unique_identifier: json[:id], published_json: json) }

    context 'with iiif assets' do
      let(:json) do
        {
          id: 'ark:/99999/fk4pp0qk3c',
          first_published_at: '2023-01-03T14:27:35Z',
          last_published_at: '2024-01-03T11:22:30Z',
          uuid: '36a224db-c416-4769-9da1-28513827d179',
          descriptive_metadata: {
            title: [{ value: 'Message from Phanias and others of the agoranomoi of Oxyrhynchus about a purchase of land.' }],
            collection: [{ value: 'University of Pennsylvania Papyrological Collection' }],
            name: [
              { value: 'creator, random', role: [{ value: 'creator' }] },
              { value: 'author, random', role: [{ value: 'author' }] },
              { value: 'contributor, random', role: [{ value: 'contributor' }] },
              { value: 'random, person', role: [] },
              { value: 'second random, person', role: [{ value: 'illustrator' }] }
            ],
            rights: [{ value: 'No Copyright', uri: 'http://rightsstatements.org/vocab/NoC-US/1.0/' }],
            date: [{ value: '2002-02-01' }, { value: '2003' }, { value: '199X' }, { value: 'ca. 2000' }]
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
                size: 1234,
                mime_type: 'image/tiff'
              }
            }
          ]
        }
      end

      it 'document contains expected fields' do
        expect(item.solr_document).to include(
          id: '99999-fk4pp0qk3c',
          uuid_ssi: '36a224db-c416-4769-9da1-28513827d179',
          unique_identifier_ssi: 'ark:/99999/fk4pp0qk3c',
          system_create_dtsi: '2023-01-03T14:27:35Z',
          system_modified_dtsi: '2024-01-03T11:22:30Z',
          thumbnail_asset_id_ssi: 'b65d33d3-8c34-4e36-acf9-dab273277583',
          iiif_manifest_path_ss: '36a224db-c416-4769-9da1-28513827d179/iiif_manifest',
          from_apotheca_bsi: 'T',
          non_iiif_asset_listing_ss: '[]',
          creator_tesim: ['creator, random', 'author, random'],
          creator_ssim: ['creator, random', 'author, random'],
          creator_with_role_tesim: ['creator, random (creator)', 'author, random (author)'],
          creator_with_role_ssim: ['creator, random (creator)', 'author, random (author)'],
          contributor_tesim: ['contributor, random', 'second random, person'],
          contributor_ssim: ['contributor, random', 'second random, person'],
          contributor_with_role_ssim: ['contributor, random (contributor)', 'second random, person (illustrator)'],
          contributor_with_role_tesim: ['contributor, random (contributor)', 'second random, person (illustrator)'],
          name_tesim: ['random, person'],
          name_ssim: ['random, person'],
          title_tesim: ['Message from Phanias and others of the agoranomoi of Oxyrhynchus about a purchase of land.'],
          title_ssim: ['Message from Phanias and others of the agoranomoi of Oxyrhynchus about a purchase of land.'],
          collection_tesim: ['University of Pennsylvania Papyrological Collection'],
          collection_ssim: ['University of Pennsylvania Papyrological Collection'],
          rights_tesim: ['http://rightsstatements.org/vocab/NoC-US/1.0/'],
          rights_ssim: ['http://rightsstatements.org/vocab/NoC-US/1.0/'],
          date_ssim: ['2002-02-01', '2003', '1990s', 'ca. 2000'],
          date_tesim: ['2002-02-01', '2003', '1990s', 'ca. 2000'],
          year_ssim: ['2002', '2003', '1990', '1991', '1992', '1993', '1994', '1995', '1996', '1997', '1998', '1999', 'ca. 2000'],
          year_tesim: ['2002', '2003', '1990', '1991', '1992', '1993', '1994', '1995', '1996', '1997', '1998', '1999', 'ca. 2000']
        )
      end
    end

    context 'with non-iiif assets' do
      let(:json) do
        {
          id: 'ark:/99999/fk4pp0qk3c',
          first_published_at: '2023-01-03T14:27:35Z',
          last_published_at: '2024-01-03T11:22:30Z',
          uuid: '36a224db-c416-4769-9da1-28513827d179',
          descriptive_metadata: {
            title: [{ value: 'Message from Phanias and others of the agoranomoi of Oxyrhynchus about a purchase of land.' }]
          },
          thumbnail_asset_id: 'b65d33d3-8c34-4e36-acf9-dab273277583',
          iiif_manifest_path: nil,
          assets: [
            {
              id: 'b65d33d3-8c34-4e36-acf9-dab273277583',
              filename: 'video.mov',
              iiif: false,
              original_file: {
                path: 'b65d33d3-8c34-4e36-acf9-dab273277583/df4f0a9b-e657-41fb-82b7-228cc9a0642b',
                size: 1234,
                mime_type: 'video/quicktime'
              },
              thumbnail_file: {
                path: 'b65d33d3-8c34-4e36-acf9-dab273277583/thumbnail',
                mime_type: 'image/jpeg'
              }
            }
          ]
        }
      end

      it 'document contains expected fields' do
        expect(item.solr_document).to include(
          id: '99999-fk4pp0qk3c',
          uuid_ssi: '36a224db-c416-4769-9da1-28513827d179',
          unique_identifier_ssi: 'ark:/99999/fk4pp0qk3c',
          system_create_dtsi: '2023-01-03T14:27:35Z',
          system_modified_dtsi: '2024-01-03T11:22:30Z',
          thumbnail_asset_id_ssi: 'b65d33d3-8c34-4e36-acf9-dab273277583',
          from_apotheca_bsi: 'T',
          iiif_manifest_path_ss: nil,
          non_iiif_asset_listing_ss: "[{\"id\":\"b65d33d3-8c34-4e36-acf9-dab273277583\",\"filename\":\"video.mov\",\"iiif\":false,\"original_file\":{\"path\":\"b65d33d3-8c34-4e36-acf9-dab273277583/df4f0a9b-e657-41fb-82b7-228cc9a0642b\",\"size\":1234,\"mime_type\":\"video/quicktime\"},\"thumbnail_file\":{\"path\":\"b65d33d3-8c34-4e36-acf9-dab273277583/thumbnail\",\"mime_type\":\"image/jpeg\"}}]",
          title_tesim: ['Message from Phanias and others of the agoranomoi of Oxyrhynchus about a purchase of land.'],
          title_ssim: ['Message from Phanias and others of the agoranomoi of Oxyrhynchus about a purchase of land.']
        )
      end
    end
  end

  describe '.add_solr_document!' do
    let(:solr_response) do
      solr = RSolr.connect(url: Settings.solr.url)
      solr.get('select', params: { q: "unique_identifier_ssi:\"#{json[:id]}\"" })
    end
    let(:item) { Item.new(unique_identifier: json[:id], published_json: json) }

    context 'without missing keys' do
      let(:json) do
        {
          id: 'ark:/99999/fk4pp0qk3c',
          first_published_at: '2023-01-03T14:27:35Z',
          last_published_at: '2024-01-03T11:22:30Z',
          uuid: '36a224db-c416-4769-9da1-28513827d179',
          descriptive_metadata: {
            title: [{ value: 'Message from Phanias and others of the agoranomoi of Oxyrhynchus about a purchase of land.' }]
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
                size: 1234,
                mime_type: 'image/tiff'
              }
            }
          ]
        }
      end

      before { item.add_solr_document! }

      it 'adds document to Solr' do
        expect(solr_response['response']['numFound']).to be 1
      end
    end

    context 'when published json missing' do
      let(:json) { {} }

      it 'raises error' do
        expect {
          item.add_solr_document!
        }.to raise_error ArgumentError, 'publish_json must be present in order to add document to Solr'
      end
    end
  end
end
