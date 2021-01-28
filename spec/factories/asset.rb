

FactoryBot.define do
  factory :asset do
    filename               { "#{Faker::Lorem.word}.tif" }
    size                   { Faker::Number.number(digits: 5)}
    original_file_location { "#{Faker::Alphanumeric.alphanumeric(number: 10)}.tif" }
    access_file_location   {"#{Faker::Alphanumeric.alphanumeric(number: 10)}.tif"}
    preview_file_location  {"#{Faker::Alphanumeric.alphanumeric(number: 10)}.tif"}
  end
end
