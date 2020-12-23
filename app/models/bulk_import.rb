# frozen_string_literal: true

class BulkImport < ActiveRecord::Base
  has_many :digital_object_imports, dependent: :destroy
  belongs_to :user
end
