# frozen_string_literal: true

module MarmiteClient
  class MissingConfiguration < StandardError; end
  class Error < StandardError; end

  # Fetches MARC XML from Marmite. Raises error if cannot retrieve MARC XML.
  #
  # @param [String] bibnumber
  # @return [String] contain MARC XML for the given bibnumber
  def self.marc21(bibnumber)
    # Get updated MARC record
    response = Faraday.get(url("/api/v2/records/#{bibnumber}/marc21?update=always"))

    raise Error, "Could not retrieve MARC for #{bibnumber}. Error: #{response.body}" unless response.success?

    response.body
  end

  # Generating IIIF Presentation Manifest.
  #
  # @return [MarmiteClient::Error] if unable to create iiif manifest
  # @return [String] body of iiif manifest if successfully created
  def self.iiif_presentation(formatted_ark, payload)
    # Create IIIF Presentation 2.0 manifest
    response = Faraday.post(url("/api/v2/records/#{formatted_ark}/iiif_presentation"), payload) do |request|
      request.options.timeout = 1200 # Wait for up to 20 minutes for response to come back.
    end

    raise Error, "Could not create IIIF Presentation Manifest for #{formatted_ark}. Error: #{response.body}" unless response.success?

    response.body
  end

  # Fetches structural metadata from Marmite.
  #
  # @param [String] bibnumber
  # @return [String] XML containing structural metadata
  def self.structural(bibnumber)
    Faraday.get(url("records/#{bibnumber}/create?format=structural")) # Create structural record.

    response = Faraday.get(url("records/#{bibnumber}/show?format=structural"))

    raise Error, "Could not retrieve Structural for #{bibnumber}. Error: #{response.body}" unless response.success?

    response.body
  end

  def self.config
    config = Rails.application.config_for(:bulwark)['marmite']
    raise MissingConfiguration, 'Missing Marmite URL' unless config['url']
    config
  end

  # Combines host and path to create a a full URL.
  def self.url(path)
    uri = Addressable::URI.parse(config['url'])
    uri.path = path
    uri.to_s
  end
end
