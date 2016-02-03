require 'faker'

FactoryGirl.define do
  factory :manuscript do
    title {Faker::Lorem.words(10, true)}
    identifier [Faker::Internet.slug]
  end

end
