# frozen_string_literal: true

FactoryBot.define do
  factory :alert_message do
    message { Faker::Lorem.sentence }
    level { AlertMessage::LEVELS.sample }
    location { AlertMessage::LOCATIONS.sample }
  end

  trait :active do
    active { true }
  end

  trait :date_limited do
    display_on { Time.zone.now + 1.day }
    display_until { Time.zone.now + 3.days }
  end
end
