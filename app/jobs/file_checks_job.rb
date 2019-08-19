class FileChecksJob < ActiveJobStatus::TrackableJob

  queue_as :file_checks

  after_perform :relay_message

  def perform(metadata_builder, root_url, user_email)
    @metadata_builder = metadata_builder
    @root_url = root_url
    @user_email = user_email
    @metadata_builder.perform_file_checks_and_generate_previews
    `sudo chown -R sceti /fs/pub/data/#{metadata_builder.repo.names.git}`
  end

  private

  def relay_message
    MessengerClient.client.publish(I18n.t('rabbitmq.publish.messages.file_checks'))
    NotificationMailer.process_completed_email(I18n.t('colenda.mailers.notification.file_checks.subject'), @user_email, I18n.t('colenda.mailers.notification.file_checks.body', :uuid => @metadata_builder.repo.unique_identifier, :root_url => @root_url, :link_fragment => @metadata_builder.repo.id)).deliver_now
  end
end