# frozen_string_literal: true

# Controller for an assets actions. For now, that's mostly downloading files.
class AssetsController < ActionController::Base
  include PresignedUrls

  class ItemNotFound < StandardError; end
  class KeyNotFound < StandardError; end

  before_action :fetch_item
  before_action :fetch_asset, except: [:thumbnail]

  rescue_from 'AssetsController::ItemNotFound', 'AssetsController::KeyNotFound' do |_e|
    head :not_found
  end

  # Download original preservation file
  def original
    config = Settings.preservation_storage
    client = client(config.to_h.except(:bucket))

    # Fetching file location from published json.
    key = @asset&.dig('original_file', 'path')

    raise KeyNotFound unless key

    redirect_to presigned_url(client, config[:bucket], key, :attachment, @asset['filename']),
                status: :temporary_redirect
  end

  # Download thumbnail
  def thumbnail
    config = Settings.derivative_storage
    client = client(config.to_h.except(:bucket))
    redirect_to presigned_url(client, config[:bucket], "#{params[:id]}/thumbnail"), status: :temporary_redirect
  end

  # Access copy download
  def access
    config = Settings.derivative_storage # For now only displaying non-iiif access copies
    client = client(config.to_h.except(:bucket))

    # Fetching file location from published json.
    key = @asset&.dig('access_file', 'path')

    raise KeyNotFound unless key

    access_ext = Mime::Type.lookup(@asset&.dig('access_file', 'mime_type')).symbol
    access_filename = "#{File.basename(@asset['filename'], '.*')}.#{access_ext}"

    redirect_to presigned_url(client, config[:bucket], key, :attachment, access_filename),
                status: :temporary_redirect
  end

  private

    # Fetch published json for asset.
    # @return [Hash]
    def fetch_asset
      assets_json = @item.published_json['assets']
      @asset = assets_json&.find { |a| a['id'] == params['id'] }
    end

    def fetch_item
      @item = Item.find_by(unique_identifier: params[:item_id])
      raise ItemNotFound unless @item
    end
end
