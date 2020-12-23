# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :digital_object_import do
    process_errors { [] }
    import_data do
      {
        type: 'type',
        assets: {
          drive: 'drive', path: 'path'
        },
        descriptive_metadata: 'JSON string',
        structural_metadata: 'JSON string',
        unique_identifier: 'id',
        directive_name: 'ark-ish'
      }
    end
  end
end
