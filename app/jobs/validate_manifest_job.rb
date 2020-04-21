class ValidateManifestJob < ActiveJobStatus::TrackableJob

  queue_as :validate_manifest

  after_perform :relay_message

  def perform(manifest, root_url, user_email)
    @manifest = manifest
    @root_url = root_url
    @user_email = user_email
    @manifest.validate_manifest
  end

  private

  def relay_message
    MessengerClient.client.publish(I18n.t('rabbitmq.publish.messages.validate_manifest'))
    NotificationMailer.process_completed_email(I18n.t('colenda.mailers.notification.validate_manifest.subject'), @user_email, I18n.t('colenda.mailers.notification.validate_manifest.body', :name => @manifest.name, :root_url => @root_url, :link_fragment => @manifest.id)).deliver_now
  end
end
