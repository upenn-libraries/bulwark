# frozen_string_literal: true
#
# Controller for Item actions. Contains actions that removes items from Solr index (AKA our publishing
# endpoint). Also contains an action to serve up our manifests.
class ItemsController < ActionController::Base
  include PresignedUrls

  class ItemNotFound < StandardError; end
  class ManifestNotFound < StandardError; end

  before_action :token_authentication, only: [:create, :destroy]
  before_action :fetch_item, only: [:destroy]
  before_action :fetch_solr_document, only: [:manifest]

  rescue_from 'ItemsController::ItemNotFound', 'ItemsController::ManifestNotFound' do |_e|
    head :not_found
  end

  # POST items/
  def create
    Item.transaction do # Wrap in a transaction in case adding document to Solr fails.
      item = Item.find_or_initialize_by(unique_identifier: params[:item][:id])
      item.published_json = params[:item]
      item.save!
      item.add_solr_document!
    end

    render json: { status: 'success' }, status: :ok # return 200 if successfully added solr document
  rescue ActiveRecord::RecordInvalid => e
    render json: { status: 'error', error: e.message }, status: :bad_request
  rescue StandardError => e
    render json: { status: 'error', error: e.message }, status: :internal_server_error
  end

  # DELETE items/:id
  def destroy
    Item.transaction do
      @item.destroy!
      @item.remove_solr_document!
    end

    render json: { status: 'success' }, status: :no_content
  rescue StandardError => e
    render json: { status: 'error', error: e.message }, status: :internal_server_error
  end

  # GET items/:id/manifest
  def manifest
    manifest_path = @document.fetch(:iiif_manifest_path_ss, nil)

    raise ManifestNotFound unless manifest_path

    config = Settings.iiif_manifest_storage
    client = client(config.to_h.except(:bucket))
    redirect_to presigned_url(client, config[:bucket], manifest_path), status: :temporary_redirect
  end

  private

    def fetch_item
      @item = Item.find_by(unique_identifier: params[:id])
      raise ItemNotFound unless @item
    end

    def fetch_solr_document
      @document = Item.find_solr_document(params[:id])
      raise ItemNotFound unless @document
    end

    def token_authentication
      authenticate_or_request_with_http_token do |token, _options|
        ActiveSupport::SecurityUtils.secure_compare(token, Settings.publishing_endpoint.token)
      end
    end
end
