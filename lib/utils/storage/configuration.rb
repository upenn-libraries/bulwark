module Utils
  module Storage
    class Configuration

      class << self
        def check_required(required_attributes, configuration)
          required_attributes.all?{|a| configuration.send(a).present?}
        end
      end

      attr_accessor :storage_type
      attr_accessor :host
      attr_accessor :port
      attr_accessor :protocol

      attr_accessor :special_remote_name
      attr_accessor :aws_access_key_id
      attr_accessor :aws_secret_access_key
      attr_accessor :encryption
      attr_accessor :request_style
      attr_accessor :public
      attr_accessor :read_host
      attr_accessor :read_protocol


      def initialize
        # Always required
        @storage_type = ENV["STORAGE_TYPE"]
        @host = ENV["STORAGE_HOST"]
        @port = ENV["STORAGE_PORT"]
        @protocol = ENV["STORAGE_PROTOCOL"]

        # Required for Ceph with S3 gateway
        @special_remote_name = ENV["SPECIAL_REMOTE_NAME"] || nil
        @aws_access_key_id = ENV["AWS_ACCESS_KEY_ID"] || nil
        @aws_secret_access_key = ENV["AWS_SECRET_ACCESS_KEY"] || nil
        @encryption = ENV["STORAGE_ENCRYPTION"] || nil
        @request_style = ENV["REQUEST_STYLE"] || nil
        @public = ENV["STORAGE_PUBLIC"] || nil
        @read_host = ENV["STORAGE_READ_HOST"] || nil
        @read_protocol = ENV["STORAGE_READ_PROTOCOL"] || nil
      end

    end
  end
end