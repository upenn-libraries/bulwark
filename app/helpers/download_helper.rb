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

      uri = Addressable::URI.parse(phalt_url)
      uri.join!("#{bucket}/#{file}")
      uri.query_values = { disposition: disposition, filename: filename }.compact
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
end
