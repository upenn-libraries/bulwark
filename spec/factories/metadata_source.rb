require 'faker'

FactoryGirl.define do

  factory :metadata_source do |f|
    f.association :metadata_builder
  end

end
