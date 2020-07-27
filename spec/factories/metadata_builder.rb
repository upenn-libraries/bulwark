require 'faker'

FactoryBot.define do
  factory :metadata_builder do
    # p_repo = FactoryBot.create(:repo)
    parent_repo { association :repo }
    source { [Faker::Internet.slug] }
  end
end
