# frozen_string_literal: true
#
# Controller for Item actions. Contains actions that removes items from Solr index (AKA our publishing
# endpoint). Also contains an action to serve up our manifests.
class ItemsController < ActionController::Base
  include PresignedUrls

  class ItemNotFound < StandardError; end

  before_action :token_authentication, only: [:create, :destroy]
  before_action :fetch_item, only: [:manifest, :destroy]

  rescue_from 'ItemsController::ItemNotFound' do |_e|
    head :not_found # respond with a 404 for missing Item (when required)
  end

  # POST items/
  def create
    begin
      Item.create(params[:item])
      render json: { status: 'success' }, status: :ok # return 200 if successfully added solr document
    rescue ArgumentError => e
      render json: { status: 'error', error: e.message }, status: :bad_request
    rescue StandardError => e
      render json: { status: 'error', error: e.message }, status: :internal_server_error
    end
  end

  # DELETE items/:id
  def destroy
    begin
      Item.delete(@item.unique_identifier)
      render json: { status: 'success' }, status: :no_content
    rescue StandardError => e
      render json: { status: 'error', error: e.message }, status: :internal_server_error
    end
  end

  # GET items/:id/manifest
  def manifest
    manifest_path = @item.fetch(:iiif_manifest_path_ss, nil)

    if manifest_path
      config = Settings.iiif_manifest_storage
      client = client(config.to_h.except(:bucket))
      redirect_to presigned_url(client, config[:bucket], manifest_path), status: :temporary_redirect
    else
      render head: :not_found
    end
  end

  private

  def fetch_item
    @item = Item.find(params[:id])
    raise ItemNotFound unless @item
  end

  def token_authentication
    authenticate_or_request_with_http_token do |token, _options|
      ActiveSupport::SecurityUtils.secure_compare(token, Settings.publishing_endpoint.token)
    end
  end
end
