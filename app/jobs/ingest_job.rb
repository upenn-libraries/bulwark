class IngestJob < ActiveJob::Base

  queue_as :ingest

  after_perform :notify_user

  def perform(metadata_builder, ingest_params)
    metadata_builder.transform_and_ingest(ingest_params)
  end

  private

  def notify_user
    NotificationMailer.process_completed_email("Ingestion", user)
  end

  def update_dashboard

  end

end
