# frozen_string_literal: true
module Bulwark
  module Storage
    # Returns download url for file.
    #
    # Based on the special remote generates correct download link. When using a S3 based
    # special remote (CEPH) downloads file from Phalt. When using directory special remote
    # uses internal download endpoint.
    def self.url_for(bucket, file, **args)
      special_remote_config = Settings.digital_object.special_remote

      case special_remote_config.type
      when 'directory'
        Storage::Local.url_for(bucket, file, args)
      when 'S3'
        Storage::Ceph.url_for(bucket, file, args)
      end
    end
  end
end
