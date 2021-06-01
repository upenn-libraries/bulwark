# frozen_string_literal: true

FactoryBot.define do
  factory :asset do
    filename                 { "#{Faker::Lorem.unique.word}.tif" }
    size                     { Faker::Number.number(digits: 5) }
    mime_type                { 'image/tiff' }
    original_file_location   { "#{Faker::Alphanumeric.alphanumeric(number: 10)}.tif" }
    access_file_location     { "#{Faker::Alphanumeric.alphanumeric(number: 10)}.tif" }
    thumbnail_file_location  { "#{Faker::Alphanumeric.alphanumeric(number: 10)}.tif" }
  end
end
