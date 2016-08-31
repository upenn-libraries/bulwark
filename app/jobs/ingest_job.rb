class IngestJob < ActiveJobStatus::TrackableJob

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
    MessengerClient.client.publish(I18n.t('rabbitmq.publish.messages.ingest'))
    NotificationMailer.process_completed_email(I18n.t('colenda.mailers.notification.ingest.subject'), @user_email, I18n.t('colenda.mailers.notification.ingest.body', :uuid => @metadata_builder.repo.unique_identifier, :root_url => @root_url, :link_fragment => @metadata_builder.repo.id)).deliver_now

  end

end
