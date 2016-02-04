require 'faker'

FactoryGirl.define do
  factory :page do
    page_id [Faker::Internet.slug]
    manu = FactoryGirl.create(:manuscript)
    parent_manuscript manu.identifier
  end

end
