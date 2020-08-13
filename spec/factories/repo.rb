require 'faker'

FactoryBot.define do
  factory :repo do
    human_readable_name { Faker::Lorem.words(number: 4, supplemental: false).map!(&:inspect).join(' ').delete!('\\"') }
    metadata_subdirectory { 'metadata' }
    assets_subdirectory { 'assets' }
    file_extensions { 'jpeg,tif' }
    preservation_filename { 'preservation.xml' }
    metadata_source_extensions { ['xlsx'] }
  end
end
