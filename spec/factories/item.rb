# frozen_string_literal: true

FactoryBot.define do
  factory :item do
    unique_identifier { 'ark:/12345/abcdef' }
    published_json do
      {
        id: 'ark:/12345/abcdef',
        first_published_at: '2023-01-03T14:27:35Z',
        last_published_at: '2024-01-03T11:22:30Z',
        uuid: '36a224db-c416-4769-9da1-28513827d179'
      }
    end

    trait :with_asset do
      published_json do
        {
          id: 'ark:/12345/abcdef',
          first_published_at: '2023-01-03T14:27:35Z',
          last_published_at: '2024-01-03T11:22:30Z',
          uuid: '36a224db-c416-4769-9da1-28513827d179',
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
    end
  end
end
