module DownloadHelper
  # TODO: Add documentation
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

  def asset_download_link(asset)
    download_link(
      asset.digital_object.names.bucket,
      asset.original_file_location,
      disposition: :inline,
      filename: File.basename(asset.filename)
    )
  end

  # @param [String, nil] filename
  # @param [String, nil] disposition
  def download_query_params(filename, disposition)
    { disposition: disposition, filename: filename }.compact if filename || disposition
  end
end
