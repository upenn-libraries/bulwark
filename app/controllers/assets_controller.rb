# frozen_string_literal: true

# Controller for an assets actions. For now, that's mostly downloading files.
class AssetsController < ActionController::Base
  include PresignedUrls

  class ItemNotFound < StandardError; end
  class FileNotFound < StandardError; end

  before_action :fetch_item, :fetch_asset

  rescue_from 'AssetsController::ItemNotFound', 'AssetsController::FileNotFound' do |_e|
    head :not_found
  end

  # Download original preservation file
  def original
    config = Settings.preservation_storage
    client = client(config.to_h.except(:bucket))

    # Fetching file location from published json.
    key = @asset&.dig('original_file', 'path')

    raise FileNotFound unless key

    redirect_to presigned_url(client, config[:bucket], key, :attachment, @asset['filename']),
                status: :temporary_redirect
  end

  # Download thumbnail
  def thumbnail
    config = Settings.derivative_storage
    client = client(config.to_h.except(:bucket))

    # Fetching file location from published json.
    key = @asset&.dig('thumbnail_file', 'path')
    raise FileNotFound unless key

    redirect_to presigned_url(client, config[:bucket], key), status: :temporary_redirect
  end

  # Access copy download
  def access
    config = Settings.derivative_storage # For now only displaying non-iiif access copies
    client = client(config.to_h.except(:bucket))

    # Fetching file location from published json.
    key = @asset&.dig('access_file', 'path')
    raise FileNotFound unless key

    access_ext = MIME::Types[@asset&.dig('access_file', 'mime_type')].first&.preferred_extension
    access_filename = "#{File.basename(@asset['filename'], '.*')}.#{access_ext}"

    redirect_to presigned_url(client, config[:bucket], key, :attachment, access_filename),
                status: :temporary_redirect
  end

  private

    # Fetch published json for asset.
    # @return [Hash]
    def fetch_asset
      @asset = @item.asset(params['id'])
    end

    def fetch_item
      @item = Item.find_by(unique_identifier: params[:item_id])
      raise ItemNotFound unless @item
    end
end
