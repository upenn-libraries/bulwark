require 'faker'

FactoryGirl.define do
  factory :page do
    page_id {Faker::Internet.slug}
    allocate = FactoryGirl.create(:manuscript)
    parent_manuscript allocate.identifier
  end

end
