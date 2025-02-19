# frozen_string_literal: true
#
# Controller for Item actions. Contains actions that removes and adds records/items. Also contains an action
# to serve up our manifests.
class ItemsController < ActionController::Base
  include PresignedUrls

  class ItemNotFound < StandardError; end
  class FileNotFound < StandardError; end

  before_action :token_authentication, only: [:create, :destroy]
  before_action :fetch_item, only: [:destroy, :thumbnail, :pdf, :manifest]

  rescue_from 'ItemsController::ItemNotFound', 'ItemsController::FileNotFound' do |_e|
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

    render json: { status: 'success' }, status: :ok
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

  # GET items/:id/thumbnail
  # Download item thumbnail.
  def thumbnail
    config = Settings.derivative_storage
    client = client(config.to_h.except(:bucket))
    thumbnail_id = @item.published_json.fetch('thumbnail_asset_id', nil)

    key = @item.asset(thumbnail_id)&.dig('thumbnail_file', 'path')
    raise FileNotFound unless key

    redirect_to presigned_url(client, config[:bucket], key), status: :temporary_redirect
  end

  # GET items/:id/pdf
  # Download item pdf.
  def pdf
    config = Settings.derivative_storage
    client = client(config.to_h.except(:bucket))
    key = @item.published_json.fetch('pdf_path', nil)
    raise FileNotFound unless key

    pdf_filename = "#{@item.published_json.dig('descriptive_metadata', 'title', 0, 'value').parameterize}.pdf"

    redirect_to presigned_url(client, config[:bucket], key, :attachment, pdf_filename), status: :temporary_redirect
  end

  # GET items/:id/manifest
  def manifest
    manifest_path = @item.published_json.fetch('iiif_manifest_path', nil)

    raise FileNotFound unless manifest_path

    config = Settings.iiif_manifest_storage
    client = Aws::S3::Client.new(**config.to_h.except(:bucket))
    r = client.get_object(bucket: config[:bucket], key: manifest_path)

    # Add CORS headers to allow external services to pull the IIIF manifest.
    # TODO: We might need to include the rack-cors gem to include a preflight check.
    response.headers['Access-Control-Allow-Origin'] = '*'

    send_data r.body.read, type: 'application/json', disposition: :inline
  rescue Aws::S3::Errors::NoSuchKey
    raise FileNotFound
  end

  private

    def fetch_item
      @item = Item.find_by(unique_identifier: params[:id])
      raise ItemNotFound unless @item
    end

    def token_authentication
      authenticate_or_request_with_http_token do |token, _options|
        ActiveSupport::SecurityUtils.secure_compare(token, Settings.publishing_endpoint.token)
      end
    end
end
