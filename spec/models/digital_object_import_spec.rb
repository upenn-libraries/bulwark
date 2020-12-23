# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DigitalObjectImport, type: :model do
  let(:bulk_import) { FactoryBot.create :bulk_import }
  let(:digital_object_import) do
    FactoryBot.build :digital_object_import,
                     bulk_import: bulk_import
  end

  it 'has one BulkImport' do
    expect(digital_object_import.bulk_import).to be bulk_import
  end

  it 'has a status' do
    expect(digital_object_import.status).to be_a String
  end

  it 'can have an Array of process_errors' do
    expect(digital_object_import.process_errors).to be_a Array
  end

  it 'has timestamps' do
    expect(digital_object_import).to respond_to :created_at, :updated_at
  end

  it 'has a import_data Hash' do
    expect(digital_object_import.import_data).to be_a Hash
  end

  context 'validations' do
    context 'status' do
      it 'defaults to queued' do
        expect(digital_object_import.status).to eq 'queued'
      end
      it 'is valid when given a valid status' do
        digital_object_import.status = 'failed'
        expect(digital_object_import.valid?).to be true
      end
      it 'is invalid with a value not in DigitalObjectImport::STATUSES' do
        invalid_import = FactoryBot.build :digital_object_import,
                                          status: 'ecstatic'
        expect(invalid_import.valid?).to be false
      end
    end
  end
end
