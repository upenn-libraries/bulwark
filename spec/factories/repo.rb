require 'faker'

FactoryBot.define do
  factory :repo do
    human_readable_name { Faker::Lorem.words(number: 4, supplemental: false).map!(&:inspect).join(' ').delete!('\\"') }
    metadata_subdirectory { 'metadata' }
    assets_subdirectory { 'assets' }
    file_extensions { 'jpeg,tif' }
    preservation_filename { 'preservation.xml' }
    metadata_source_extensions { ['xlsx'] }
    new_format { false }

    trait :with_assets do
      new_format { true }

      after(:create) do |repo|
        FactoryBot.create_list(:asset, 2, repo: repo)
      end
    end

    trait :with_structural_metadata do
      with_assets

      after(:create) do |repo|
        structural_metadata = repo.assets.map.with_index do |asset, index|
          {
            'sequence' => index,
            'viewing_direction' => MetadataSource::LEFT_TO_RIGHT,
            'display' => MetadataSource::PAGED,
            'label' => "Page #{index}",
            'table_of_contents' => ["Image #{index}"],
            'filename' => asset.filename
          }
        end

        MetadataSource.create(
          source_type: 'structural',
          metadata_builder: repo.metadata_builder,
          user_defined_mappings: {
            'sequence' => structural_metadata
          }
        )
      end
    end

    trait :with_descriptive_metadata do
      after(:create) do |repo|
        MetadataSource.create(
          source_type: 'descriptive',
          metadata_builder: repo.metadata_builder,
          user_defined_mappings: {
            "call_number" => ["Ms. Coll 200 box 180 folder 8576 item 2"],
            "collection" => ["Marian Anderson Papers (University of Pennsylvania)"],
            "corporate_name" => [
              "McMillin Academic Theater, Columbia University",
              "Hurok Attractions, Inc. ",
              "Institute of Arts and Sciences, Columbia University"
            ],
            "date" => ["1941-12-20T20:30:00"],
            "description" => [
              "Handel, George Frideric: Tutta raccolta ancor; Martini, Johann Paul Aegidius: Plaisir d'amour; Bassani, Giovanni Battista: Dormi, bella, dormi tu?; Carissimi, Giacomo: No, no, non si speri!; Schubert, Franz: Fragment aus dem Aeschylus, D 450; Schubert, Franz: Fischerweise : D881; Schubert, Franz: Der Doppelgänger; Schubert, Franz: Der Erlkönig; Massenet, Jules: Pleurez, pleurez mes yeux, from Le Cid; Dvořák, Antonín: Als die alte Mutter: Songs my mother taught me; Rachmaninoff, Sergei: Christ is risen : op. 26, no. 6; Quilter, Roger: O mistress mine; Quilter, Roger: Blow, blow, thou winter wind; Burleigh, Harry Thacker (arr.): Go down, Moses: Let my people go; Lawrence, William (arr.): Let us break bread together; Boatner, Edward (arr.): Trampin'; Johnson, Hall (arr.): Honor, honor"
            ],
            "format" => ["2 p. ; 24 cm"],
            "geographic_subject" => ["New York City, New York, United States"],
            "item_type" => ["Programs"],
            "language" => ["English"],
            "personal_name" => ["Anderson, Marian", "Rupp, Franz", "Hurok, Sol"],
            "rights" => ["https://creativecommons.org/publicdomain/zero/1.0/"],
            "title" => ["[Concert program 1941-12-20]"]
          }
        )
      end
    end

    trait :published do
      first_published_at { Time.current - 1.day }
      last_published_at { Time.current }
    end
  end
end
