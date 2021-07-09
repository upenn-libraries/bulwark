# frozen_string_literal: true

FactoryBot.define do
  factory :alert_message do
    message { Faker::Lorem.sentence }
    level { AlertMessage::LEVELS.sample }
    location { AlertMessage::LOCATIONS.sample }
  end
end
