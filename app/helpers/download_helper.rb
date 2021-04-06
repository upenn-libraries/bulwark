# frozen_string_literal: true
module DownloadHelper
  # Returns download url for file.
  #
  # Based on the special remote generates correct download link. When using a S3 based
  # special remote (CEPH) downloads file from Phalt. When using directory special remote
  # uses internal download endpoint.
  def download_link(bucket, file, disposition: nil, filename: nil)
    special_remote_config = Bulwark::Config.special_remote
    case special_remote_config[:type]
    when 'directory'
      special_remote_download_url(bucket, file, disposition: disposition, filename: filename)
    when 'S3'
      phalt_url = Bulwark::Config.phalt[:url]
      raise 'Phalt endpoint not configured' if phalt_url.blank?

      phalt_url += '/' unless phalt_url[-1] == '/'
      uri = Addressable::URI.parse(phalt_url)
      uri.join!("download/#{bucket}/#{file}")
      uri.query_values = download_query_params filename, disposition
      uri.to_s
    end
  end

  def original_file_link(asset)
    download_link(
      asset.repo.names.bucket,
      asset.original_file_location,
      disposition: :attachment,
      filename: File.basename(asset.filename, '.*')
    )
  end

  def access_file_link(asset)
    download_link(
      asset.repo.names.bucket,
      asset.access_file_location,
      disposition: :attachment,
      filename: File.basename(asset.filename, '.*')
    )
  end

  def thumbnail_file_link(asset)
    download_link(
      asset.repo.names.bucket,
      asset.thumbnail_file_location
    )
  end

  # @param [String, nil] filename
  # @param [String, nil] disposition
  def download_query_params(filename, disposition)
    { disposition: disposition, filename: filename }.compact if filename || disposition
  end
end
