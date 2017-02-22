require_relative 'configuration'

module Utils
  module Storage
    class Ceph
      class << self
        def config
          @config ||= Configuration.new
        end

        def configure
          yield config
        end

        def required_configs
          Utils::Storage::Configuration.check_required([:special_remote_name, :aws_access_key_id, :aws_secret_access_key, :storage_type, :encryption, :request_style, :host, :port, :protocol, :public], self.config)
        end
        alias_method :required_configs?, :required_configs
      end
    end
  end
end