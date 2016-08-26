class GenerateXmlJob < ActiveJob::Base

  queue_as :xml

  after_perform :relay_message

  def perform(metadata_builder, root_url)
    @root_url = root_url
    @metadata_builder = metadata_builder
    metadata_builder.build_xml_files
  end

  private

  def relay_message
    MessengerClient.client.publish("XML generated")
    NotificationMailer.process_completed_email("Preservation XML Generated", "katherly@upenn.edu", "Preservation-level XML generated for #{@metadata_builder.repo.unique_identifier} has been generated and is ready for review.\n\nReview at: #{@root_url}admin_repo/repo/#{@metadata_builder.repo.id}/preview_xml").deliver_now

  end

end
