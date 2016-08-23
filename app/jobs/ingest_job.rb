class IngestJob < ActiveJob::Base

  queue_as :ingest

  def perform(metadata_builder, ingest_params)
    metadata_builder.transform_and_ingest(ingest_params)
  end

end
