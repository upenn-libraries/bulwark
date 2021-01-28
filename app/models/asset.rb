class Asset < ActiveRecord::Base
  belongs_to :repo

  validates :filename, presence: true
  # size is in bytes
end
