class IngestJob < ActiveJob::Base

  queue_as :ingest

  after_perform :relay_message

  def perform(metadata_builder, ingest_params)
    metadata_builder.transform_and_ingest(ingest_params)
  end

  private

  def relay_message
    MessengerClient.client.publish("Ingest complete")
  end

end
