module AdminHelper
  def special_remote_download_url(path)
    special_remote_config = Utils.config['special_remote']
    case special_remote_config['type']
    when 'directory'
      bucket, key = path.split('/') # TODO: might need to change the method definition instead of doing this.
      admin_special_remote_download_url(bucket, key)
    when 'S3'
      Addressable::URI.new(
        path: path,
        host: Utils::Storage::Ceph.config.read_host,
        scheme: Utils::Storage::Ceph.config.read_protocol.gsub('://', '')
      ).to_s
    end
  end
end
