# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_import do
    association :created_by, strategy: :build, factory: :user
  end
end
