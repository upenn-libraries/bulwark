class GenerateXmlJob < ActiveJob::Base

  queue_as :xml

  def perform(metadata_builder)
    metadata_builder.build_xml_files
  end

end
