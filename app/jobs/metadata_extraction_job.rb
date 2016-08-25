class MetadataExtractionJob < ActiveJob::Base

  queue_as :metadata_extraction

  after_perform :relay_message

  def perform(metadata_builder)
    metadata_builder.refresh_metadata
  end

  private

  def relay_message
    MessengerClient.client.publish("Metadata extracted")
  end

end
