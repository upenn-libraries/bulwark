# frozen_string_literal: true
class GenerateDerivativesJob < ActiveJob::Base
  queue_as :high

  # Need to catch error in case digital_object import no longer exists
  rescue_from ActiveJob::DeserializationError do |_exception|
    # TODO: Not sure what the correct action is here. We could silently fail
    # since the repo no longer exists.
    raise 'Repo no longer exists'
  end

  def perform(repo)
    repo.generate_derivatives
    repo.create_iiif_manifest
  end
end
