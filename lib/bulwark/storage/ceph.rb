# frozen_string_literal: true

module Bulwark
  module Storage
    module Ceph
      # Return url for files stored in Ceph. We proxy these requests through Phalt in
      # order to change the name of the downloaded file.
      def self.url_for(bucket, file, disposition: nil, filename: nil)
        phalt_url = Settings.phalt.url
        raise 'Phalt endpoint not configured' if phalt_url.blank?

        phalt_url += '/' unless phalt_url[-1] == '/'
        uri = Addressable::URI.parse(phalt_url)
        uri.join!("download/#{bucket}/#{file}")
        uri.query_values = download_query_params filename, disposition
        uri.to_s
      end

      # @param [String, nil] filename
      # @param [String, nil] disposition
      def self.download_query_params(filename, disposition)
        { disposition: disposition, filename: filename }.compact if filename || disposition
      end
    end
  end
end
