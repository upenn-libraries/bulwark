require 'faker'

FactoryGirl.define do

  factory :metadata_builder do
    association :repo
  end

end
