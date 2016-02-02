require 'faker'

FactoryGirl.define do
  factory :repo do
    title {Faker::Lorem.words(4, true)}
    directory {Faker::Lorem.words(1, true)}
    metadata_subdirectory {Faker::Lorem.words(1, true)}
    assets_subdirectory {Faker::Lorem.words(1, true)}
    metadata_filename "structure.xml"
    file_extensions "jpeg,tif"
  end
end
