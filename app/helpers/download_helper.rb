# frozen_string_literal: true
module DownloadHelper
  # Returns download url for file.
  #
  # Based on the special remote generates correct download link. When using a S3 based
  # special remote (CEPH) downloads file from Phalt. When using directory special remote
  # uses internal download endpoint.
  def download_link(bucket, file, disposition: nil, filename: nil)
    Bulwark::Storage.url_for(bucket, file, disposition: disposition, filename: filename)
  end
end
