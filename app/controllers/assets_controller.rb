# frozen_string_literal: true

# Controller for an assets actions. For now, that's mostly downloading files.
class AssetsController < ActionController::Base
  include PresignedUrls

  class ItemNotFound < StandardError; end

  before_action :fetch_item

  # Download original preservation file
  # use pre-signed urls with an expiry period of one minute
  def original
    config = Settings.preservation_storage
    client = client(config.to_h.except(:bucket))

    assets_json = @item.raw_json[:assets]
    key = assets_json.find { |a| a[:id] == params[:id] }&.dig(:original_file, :path)

    if key
      redirect_to presigned_url(client, config[:bucket], key), status: :temporary_redirect
    else
      render head: :not_found
    end
  end

  # Download thumbnail
  def thumbnail
    config = Settings.derivative_storage
    client = client(config.to_h.except(:bucket))
    redirect_to presigned_url(client, config[:bucket], "#{params[:id]}/thumbnail"), status: :temporary_redirect
  end

  # Access copy download
  def access
    config = Settings.derivative_storage # for now only displaying non-iiif access copies
    client = client(config.to_h.except(:bucket))
    redirect_to presigned_url(client, config[:bucket], "#{params[:id]}/access"), status: :temporary_redirect
  end

  private

    def fetch_item
      @item = Item.find(params[:item_id])
      raise ItemNotFound unless @item
    end
end
