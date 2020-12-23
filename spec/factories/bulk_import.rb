# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :bulk_import do
    association :user, strategy: :build
  end
end
