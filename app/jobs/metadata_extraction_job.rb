class MetadataExtractionJob < ActiveJob::Base

  queue_as :metadata_extraction

  def perform(metadata_builder)
    metadata_builder.refresh_metadata
  end

end
