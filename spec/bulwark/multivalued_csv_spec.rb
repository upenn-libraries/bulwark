require 'rails_helper'

RSpec.describe Bulwark::MultivaluedCSV do
  let(:csv_string_data) do
    <<~CSV
      unique_identifier,creator[1],creator[2],description[1],other data,date[1],date[2]
      ark:/9999/test,"person, random first","person, random second",very important item,this is a test item,2020-01-01,2020-01-02
      ark:/9999/test2,"person, random third","person, random forth",second most important item,this is a second test item,2020-02-01,
    CSV
  end

  let(:sorted_csv_string_data) do
    <<~CSV
      creator[1],creator[2],date[1],date[2],description[1],other data,unique_identifier
      "person, random first","person, random second",2020-01-01,2020-01-02,very important item,this is a test item,ark:/9999/test
      "person, random third","person, random forth",2020-02-01,,second most important item,this is a second test item,ark:/9999/test2
    CSV
  end

  let(:csv_hash_data) do
    [
      { 'unique_identifier' => 'ark:/9999/test', 'creator' => ['person, random first', 'person, random second'], 'description' => ['very important item'], 'other data' => 'this is a test item', 'date' => ['2020-01-01', '2020-01-02'] },
      { 'unique_identifier' => 'ark:/9999/test2', 'creator' => ['person, random third', 'person, random forth'], 'description' => ['second most important item'], 'other data' => 'this is a second test item', 'date' => ['2020-02-01'] }
    ]
  end

  describe '.parse' do
    it 'parses data as expected' do
      expect(Bulwark::MultivaluedCSV.parse(csv_string_data)).to eql csv_hash_data
    end
  end

  describe '.generate' do
    it 'generates data as expected' do
      expect(Bulwark::MultivaluedCSV.generate(csv_hash_data)).to eql sorted_csv_string_data
    end
  end
end
