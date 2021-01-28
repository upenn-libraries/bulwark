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
  end
end
