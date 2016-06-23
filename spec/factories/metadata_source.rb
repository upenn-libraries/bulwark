require 'faker'

FactoryGirl.define do

  factory :metadata_source do
    association :metadata_builder
    path "tmp/this"
  end

end
