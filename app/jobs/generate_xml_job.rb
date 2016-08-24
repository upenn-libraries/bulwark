class GenerateXmlJob < ActiveJob::Base

  queue_as :xml

  after_perform :update_dashboard

  def perform(metadata_builder)
    metadata_builder.build_xml_files
  end

  private

  def notify_user
    NotificationMailer.process_completed_email("Generation of Preservation XML", user)
  end

  def update_dashboard

  end

end
