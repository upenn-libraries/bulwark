# frozen_string_literal: true

# Concern that provides methods to create presigned urls that download files in AWS S3.
module PresignedUrls
  extend ActiveSupport::Concern

  private

    def client(**config)
      Aws::S3::Client.new(**config)
    end

    # Returns AWS S3 presigned url that expires in 5 minutes.
    def presigned_url(client, bucket, key, disposition = :inline, filename = nil)
      content_disposition = disposition
      content_disposition = "#{content_disposition}; filename=\"#{filename}\"" if filename

      signer = Aws::S3::Presigner.new(client: client)
      signer.presigned_url(
        :get_object, bucket: bucket, key: key, expires_in: 300, response_content_disposition: content_disposition
      )
    end
end
