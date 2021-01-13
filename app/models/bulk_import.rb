# frozen_string_literal: true

class BulkImport < ActiveRecord::Base
  has_many :digital_object_imports, dependent: :destroy
  belongs_to :created_by, class_name: User

  # kamanari config
  paginates_per 5
  max_paginates_per 100

  delegate :email, to: :created_by, prefix: true
end
