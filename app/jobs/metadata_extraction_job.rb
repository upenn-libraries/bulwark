class MetadataExtractionJob < ActiveJob::Base

  queue_as :metadata_extraction

  after_perform :update_dashboard

  def perform(metadata_builder)
    metadata_builder.refresh_metadata
  end

  private

  def notify_user
    NotificationMailer.process_completed_email("Metadata Extraction", user)
  end

  def update_dashboard

  end

end
