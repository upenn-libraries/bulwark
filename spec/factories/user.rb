# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :user do
    email { Faker::Internet.safe_email }
    encrypted_password { Faker::Internet.password }
  end
end
