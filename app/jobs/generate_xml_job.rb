class GenerateXmlJob < ActiveJob::Base

  queue_as :xml

  after_perform :relay_message

  def perform(metadata_builder)
    metadata_builder.build_xml_files
  end

  private

  def relay_message
    MessengerClient.client.publish("XML generated")
  end

end
