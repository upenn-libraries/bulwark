# frozen_string_literal: true

class BulkImport < ActiveRecord::Base
  has_many :digital_object_imports, dependent: :destroy
  belongs_to :created_by, class_name: User
end
