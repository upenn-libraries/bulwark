class MetadataExtractionJob < ActiveJob::Base

  queue_as :metadata_extraction

  after_perform do
    relay_message
  end

  def perform(metadata_builder, root_url)
    @root_url = root_url
    @metadata_builder = metadata_builder
    @metadata_builder.refresh_metadata
  end

  private

  def relay_message
    MessengerClient.client.publish("Metadata extracted")
    NotificationMailer.process_completed_email("Metadata Extraction", "katherly@upenn.edu", "Metadata extraction complete for #{@metadata_builder.repo.unique_identifier}\n\nReview at: #{@root_url}admin_repo/repo/#{@metadata_builder.repo.id}/generate_metadata").deliver_now
  end

end
