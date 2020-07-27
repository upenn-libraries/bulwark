require 'faker'

FactoryBot.define do
  factory :page do
    page_id { [Faker::Internet.slug] }
    manu = FactoryBot.create(:manuscript)
    parent_manuscript { manu.identifier }
  end

end
