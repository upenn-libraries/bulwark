class GenerateXmlJob < ActiveJobStatus::TrackableJob

  queue_as :xml

  after_perform :relay_message

  def perform(metadata_builder, root_url, user_email)
    @metadata_builder = metadata_builder
    @root_url = root_url
    @user_email = user_email
    @metadata_builder.build_xml_files
  end

  private

  def relay_message
    NotificationMailer.process_completed_email(I18n.t('colenda.mailers.notification.generate_xml.subject'), @user_email, I18n.t('colenda.mailers.notification.generate_xml.body', :uuid => @metadata_builder.repo.unique_identifier, :root_url => @root_url, :link_fragment => @metadata_builder.repo.id)).deliver_now
  end
end
