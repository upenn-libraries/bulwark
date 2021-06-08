# frozen_string_literal: true

class Asset < ActiveRecord::Base
  belongs_to :repo, required: true

  validates :filename, presence: true, uniqueness: { scope: :repo }
  # size is in bytes

  # Helper methods that provide download links for the original file, access copy and thumbnail.

  # Returns filename without extensions. If there are multiple extensions removes all of them.
  def filename_basename
    extension = filename.match(/(?<ext>(?:\.[^.]{1,4})+)$/)[:ext]
    File.basename(filename, extension)
  end

  def original_file_link(disposition: :attachment)
    Bulwark::Storage.url_for(
      repo.names.bucket,
      original_file_location,
      disposition: disposition,
      filename: filename_basename
    )
  end

  def access_file_link(disposition: :attachment)
    Bulwark::Storage.url_for(
      repo.names.bucket,
      access_file_location,
      disposition: disposition,
      filename: filename_basename
    )
  end

  def thumbnail_file_link
    Bulwark::Storage.url_for(
      repo.names.bucket, thumbnail_file_location
    )
  end
end
