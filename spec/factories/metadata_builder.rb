require 'faker'

FactoryGirl.define do
  factory :metadata_builder do
    p_repo = FactoryGirl.create(:repo)
    parent_repo p_repo.id
    source [Faker::Internet.slug]
  end
end
