# frozen_string_literal: true

module MarmiteClient
  class MissingConfiguration < StandardError; end
  class Error < StandardError; end

  # Fetches MARC XML from Marmite. Raises error if cannot retrieve MARC XML.
  #
  # @param [String] bibnumber
  # @return [String] contain MARC XML for the given bibnumber
  def self.marc21(bibnumber)
    Faraday.get(url("records/#{bibnumber}/create?format=marc21")) # Create MARC Record.

    response = Faraday.get(url("records/#{bibnumber}/show?format=marc21"))

    raise Error, "Could not retrieve MARC for #{bibnumber}. Error: #{response.body}" unless response.success?

    response.body
  end

  # @return [MarmiteClient::Error] if unable to create iiif manifest
  # @return [String] body of iiif manifest if successfully created
  def self.iiif_presentation(formatted_ark)
    # Create IIIF Presentation 2.0 Manifest
    Faraday.get(url("records/#{formatted_ark}/create?format=iiif_presentation")) do |request|
      # Increasing timeout of request, because the generation of a IIIF presentation manifest can take a while.
      request.options.timeout = 360
    end

    response = Faraday.get(url("records/#{formatted_ark}/show?format=iiif_presentation"))

    raise Error, "Could not create IIIF Presentation Manifest for #{formatted_ark}. Error: #{response.body}" unless response.success?

    response.body
  end

  # TODO: Structural metadata will also be fetched from Marmite.
  # def structural(bibnumber); end

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
