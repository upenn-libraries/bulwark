class Asset < ActiveRecord::Base
  belongs_to :repo, required: true

  validates :filename, presence: true, uniqueness: { scope: :repo }
  # size is in bytes
end
