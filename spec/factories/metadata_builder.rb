require 'faker'

FactoryGirl.define do

  factory :metadata_builder do |f|
    f.association :repo
    metadata_source [FactoryGirl.create(:metadata_source), FactoryGirl.create(:metadata_source)]
  end

end
