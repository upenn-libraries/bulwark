# frozen_string_literal: true

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

    trait :successful do
      status { DigitalObjectImport::SUCCESSFUL }
    end

    trait :failed do
      status { DigitalObjectImport::FAILED }
    end

    trait :in_progress do
      status { DigitalObjectImport::IN_PROGRESS }
    end

    trait :queued do
      status { DigitalObjectImport::QUEUED }
    end
  end
end
