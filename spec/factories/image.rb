require 'faker'

FactoryBot.define do
  factory :image do
    page_id { [Faker::Internet.slug] }
    parent_manuscript { association :manuscript }

    # after_build do |image|
    #   manuscript = FactoryBot.create(:manuscript)
    #   parent_manuscript = manuscript.identifier
    # end
  end
end
