class MetadataExtractionJob < ActiveJobStatus::TrackableJob

  queue_as :metadata_extraction

  after_perform :relay_message

  def perform(metadata_builder, root_url, user_email)
    @metadata_builder = metadata_builder
    @root_url = root_url
    @user_email = user_email
    @metadata_builder.refresh_metadata
  end

  private

  def relay_message
    NotificationMailer.process_completed_email(I18n.t('colenda.mailers.notification.metadata_extraction.subject'), @user_email, I18n.t('colenda.mailers.notification.metadata_extraction.body', :uuid => @metadata_builder.repo.unique_identifier, :root_url => @root_url, :link_fragment => @metadata_builder.repo.id)).deliver_now
  end

end