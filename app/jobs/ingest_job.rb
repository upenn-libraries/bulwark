class IngestJob < ActiveJob::Base

  queue_as :ingest

  after_perform :relay_message

  def perform(metadata_builder, ingest_params, root_url, user_email)
    @metadata_builder = metadata_builder
    @root_url = root_url
    @user_email = user_email
    metadata_builder.transform_and_ingest(ingest_params)
  end

  private

  def relay_message
    MessengerClient.client.publish("Ingest complete")
    NotificationMailer.process_completed_email("Ingestion and Derivative Generation", @user_email, "#{@metadata_builder.repo.unique_identifier} has been ingested and its derivatives generated.  It is ready for review.\n\nReview at: #{@root_url}admin_repo/repo/#{@metadata_builder.repo.id}/ingest").deliver_now

  end

end
