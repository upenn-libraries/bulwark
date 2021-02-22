# frozen_string_literal: true

class ProcessDigitalObjectImportJob < ActiveJob::Base
  queue_as :low

  # Need to catch error in case digital_object import no longer exists
  rescue_from ActiveJob::DeserializationError do |exception|
    # TODO: Not sure what the correct action is here. We could silently fail
    # since the import no longer exists.
    raise 'Digital object import no longer exists'
  end

  def perform(digital_object_import)
    digital_object_import.process
  end
end
