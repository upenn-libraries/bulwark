# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkImport, type: :model do
  let(:bulk_import) do
    FactoryBot.build :bulk_import,
                     digital_object_imports: FactoryBot.build_list(:digital_object_import, 1)
  end

  it 'has many DigitalObjectImports' do
    expect(bulk_import.digital_object_imports).to be_a ActiveRecord::Associations::CollectionProxy
    expect(bulk_import.digital_object_imports.first).to be_a DigitalObjectImport
  end

  it 'returns a User using created_by' do
    expect(bulk_import.created_by).to be_a User
  end

  it 'has timestamps' do
    expect(bulk_import).to respond_to :created_at, :updated_at
  end
end
