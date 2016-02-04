require 'faker'

FactoryGirl.define do
  factory :repo do
    title {Faker::Lorem.words(4, false).map!(&:inspect).join(' ').delete!('\\"')}
    directory {Faker::Lorem.words(1, false).map!(&:inspect).join(' ').delete!('\\"')}
    metadata_subdirectory {Faker::Lorem.words(1, true).map!(&:inspect).join(' ').delete!('\\"')}
    assets_subdirectory {Faker::Lorem.words(1, true).map!(&:inspect).join(' ').delete!('\\"')}
    metadata_filename "structure.xml"
    file_extensions "jpeg,tif"
  end
end
