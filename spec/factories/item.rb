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

    # Item with image will include IIIF manifest, PDF and excludes access copies.
    trait :with_image do
      published_json do
        {
          id: 'ark:/12345/abcdef',
          first_published_at: '2023-01-03T14:27:35Z',
          last_published_at: '2024-01-03T11:22:30Z',
          uuid: '36a224db-c416-4769-9da1-28513827d179',
          thumbnail_asset_id: 'b65d33d3-8c34-4e36-acf9-dab273277583',
          iiif_manifest_path: '36a224db-c416-4769-9da1-28513827d179/iiif_manifest',
          pdf_path: '36a224db-c416-4769-9da1-28513827d179/pdf',
          descriptive_metadata: {
            title: [{ value: 'Very important item' }]
          },
          assets: [
            {
              id: 'b65d33d3-8c34-4e36-acf9-dab273277583',
              filename: 'e2750_wk1_body0001.tif',
              iiif: true,
              original_file: {
                path: 'b65d33d3-8c34-4e36-acf9-dab273277583/df4f0a9b-e657-41fb-82b7-228cc9a0642b',
                size: 1234,
                mime_type: 'image/tiff'
              },
              thumbnail_file: {
                path: 'b65d33d3-8c34-4e36-acf9-dab273277583/thumbnail',
                size: 1234,
                mime_type: 'image/jpeg'
              }
            }
          ]
        }
      end
    end

    # Item with video includes access copies for assets.
    trait :with_video do
      published_json do
        {
          id: 'ark:/12345/abcdef',
          first_published_at: '2023-01-03T14:27:35Z',
          last_published_at: '2024-01-03T11:22:30Z',
          uuid: '36a224db-c416-4769-9da1-28513827d179',
          thumbnail_asset_id: 'b65d33d3-8c34-4e36-acf9-dab273277583',
          iiif_manifest_path: nil,
          pdf_path: nil,
          assets: [
            {
              id: 'b65d33d3-8c34-4e36-acf9-dab273277583',
              filename: 'e2750_wk1_vid0001.mov',
              iiif: true,
              original_file: {
                path: 'b65d33d3-8c34-4e36-acf9-dab273277583/df4f0a9b-e657-41fb-82b7-228cc9a0642b',
                size: 1234,
                mime_type: 'video/quicktime'
              },
              thumbnail_file: {
                path: 'b65d33d3-8c34-4e36-acf9-dab273277583/thumbnail',
                size: 1234,
                mime_type: 'image/jpeg'
              },
              access_file: {
                path: 'b65d33d3-8c34-4e36-acf9-dab273277583/access',
                size: 1234,
                mime_type: 'video/mp4'
              }
            }
          ]
        }
      end
    end

    # Item with pdf includes does not include thumbnails or access copies for assets.
    trait :with_pdf do
      published_json do
        {
          id: 'ark:/12345/abcdef',
          first_published_at: '2023-01-03T14:27:35Z',
          last_published_at: '2024-01-03T11:22:30Z',
          uuid: '36a224db-c416-4769-9da1-28513827d179',
          thumbnail_asset_id: 'b65d33d3-8c34-4e36-acf9-dab273277583',
          iiif_manifest_path: nil,
          pdf_path: nil,
          assets: [
            {
              id: 'b65d33d3-8c34-4e36-acf9-dab273277583',
              filename: 'e2750_wk1.pdf',
              iiif: true,
              original_file: {
                path: 'b65d33d3-8c34-4e36-acf9-dab273277583/df4f0a9b-e657-41fb-82b7-228cc9a0642b',
                size: 1234,
                mime_type: 'application/pdf'
              }
            }
          ]
        }
      end
    end
  end
end
