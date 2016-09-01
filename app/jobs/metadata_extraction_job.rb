class MetadataExtractionJob < ActiveJobStatus::TrackableJob

  queue_as :metadata_extraction

  after_perform do
    relay_message
  end

  def perform(metadata_builder, root_url, user_email)
    @metadata_builder = metadata_builder
    @root_url = root_url
    @user_email = user_email
    @metadata_builder.refresh_metadata
  end

  private

  def relay_message
    MessengerClient.client.publish(I18n.t('rabbitmq.publish.messages.metadata_extraction'))
    NotificationMailer.process_completed_email(I18n.t('colenda.mailers.notification.metadata_extraction.subject'), @user_email, I18n.t('colenda.mailers.notification.metadata_extraction.body', :uuid => @metadata_builder.repo.unique_identifier, :root_url => @root_url, :link_fragment => @metadata_builder.repo.id)).deliver_now
  end

end
