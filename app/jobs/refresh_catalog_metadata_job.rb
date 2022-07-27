# frozen_string_literal: true
class RefreshCatalogMetadataJob < ActiveJob::Base
  queue_as :high

  # Need to catch error in case digital_object import no longer exists
  rescue_from ActiveJob::DeserializationError do |_exception|
    # TODO: Not sure what the correct action is here. We could silently fail
    # since the repo no longer exists.
    raise 'Repo no longer exists'
  end

  # Refreshing catalog metadata.
  #
  # In the future, there will be better ways to do this but for now, this should cover all of our bases. We are cloning
  # a repo and reading the descriptive metadata from there and merging it with fresh catalog metadata. We also update
  # the preservation metadata and recreate the IIIF manifest. The repo is republished if it was previously published.
  def perform(repo)
    repo.update_catalog_metadata
    repo.add_preservation_and_mets_xml
    repo.delete_clone
    repo.create_iiif_manifest if Settings.bulk_import.create_iiif_manifest
    repo.publish if repo.published
  end
end
