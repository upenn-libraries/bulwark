# frozen_string_literal: true
module Bulwark
  module Storage
    module Local
      def self.url_for(bucket, file, disposition: nil, filename: nil)
        Rails.application.routes.url_helpers.special_remote_download_url(bucket, file, disposition: disposition, filename: filename)
      end
    end
  end
end
