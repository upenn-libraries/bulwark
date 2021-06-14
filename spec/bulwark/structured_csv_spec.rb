# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Bulwark::StructuredCSV do
  let(:csv_string_data) do
    <<~CSV
      asset.drive,asset.path,unique_identifier,metadata.creator[1],metadata.creator[2],metadata.description[1],metadata.other data,metadata.date[1],metadata.date[2],metadata.subject[1],structural.files.number,structural.sequence[1].label,structural.sequence[1].filename,structural.sequence[1].table_of_contents[1],structural.sequence[2].label,structural.sequence[2].filename,structural.sequence[2].table_of_contents[1]
      test,path/to/assets_1,ark:/9999/test,"person, random first","person, random second",very important item,this is a test item,2020-01-01,2020-01-02,subject one,3,,,,,
      test,path/to/assets_2,ark:/9999/test2,"person, random third","person, random forth",second most important item,this is a second test item,2020-02-01,,,4,Front,front.jpeg,Illuminated Image,Back,back.jpeg,Second Illuminated Image
    CSV
  end

  let(:sorted_csv_string_data) do
    <<~CSV
    asset.drive,asset.path,metadata.creator[1],metadata.creator[2],metadata.date[1],metadata.date[2],metadata.description[1],metadata.other data,metadata.subject[1],structural.files.number,structural.sequence[1].filename,structural.sequence[1].label,structural.sequence[1].table_of_contents[1],structural.sequence[2].filename,structural.sequence[2].label,structural.sequence[2].table_of_contents[1],unique_identifier
    test,path/to/assets_1,"person, random first","person, random second",2020-01-01,2020-01-02,very important item,this is a test item,subject one,3,,,,,,,ark:/9999/test
    test,path/to/assets_2,"person, random third","person, random forth",2020-02-01,,second most important item,this is a second test item,,4,front.jpeg,Front,Illuminated Image,back.jpeg,Back,Second Illuminated Image,ark:/9999/test2
    CSV
  end

  let(:csv_hash_data) do
    [
      {
        'asset' => {
          'drive' => 'test',
          'path' => 'path/to/assets_1'
        },
        'unique_identifier' => 'ark:/9999/test',
        'metadata' => {
          'creator' => ['person, random first', 'person, random second'],
          'description' => ['very important item'],
          'subject' => ['subject one'],
          'other data' => 'this is a test item',
          'date' => ['2020-01-01', '2020-01-02']
        },
        'structural' => {
          'files' => { 'number' => '3' },
          'sequence' => []
        }
      },
      {
        'asset' => {
          'drive' => 'test',
          'path' => 'path/to/assets_2'
        },
        'unique_identifier' => 'ark:/9999/test2',
        'metadata' => {
          'creator' => ['person, random third', 'person, random forth'],
          'description' => ['second most important item'],
          'subject' => [],
          'other data' => 'this is a second test item',
          'date' => ['2020-02-01']
        },
        'structural' => {
          'sequence' => [
            {
              'label' => 'Front',
              'filename' => 'front.jpeg',
              'table_of_contents' => ['Illuminated Image']
            },
            {
              'label' => 'Back',
              'filename' => 'back.jpeg',
              'table_of_contents' => ['Second Illuminated Image']
            }
          ],
          'files' => { 'number' => '4' }
        }
      }
    ]
  end

  describe '.parse' do
    it 'parses data as expected' do
      expect(described_class.parse(csv_string_data)).to eql csv_hash_data
    end
  end

  describe '.generate' do
    it 'generates data as expected' do
      expect(described_class.generate(csv_hash_data)).to eql sorted_csv_string_data
    end
  end
end
