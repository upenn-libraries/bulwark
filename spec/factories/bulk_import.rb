# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_import do
    association :user, strategy: :build
  end
end
