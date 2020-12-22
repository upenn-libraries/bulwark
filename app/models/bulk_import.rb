# frozen_string_literal: true

class BulkImport < ActiveRecord::Base
  has_many :digital_object_imports, dependent: :destroy
  has_one :user
end
