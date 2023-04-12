# frozen_string_literal: true

class MigrationController < ActionController::Base
  # before_action :authenticate_token! # TODO: ???

  # TODO: check if already migrated?
  def serialize
    # load object(s)
    # build hash in expected format
    # convert to json
    # respond
    render json: {}.to_json # TODO: use Oj?
  end

  # def mark_migrated
  #   # TODO: Apotheca could POST here and we can mark the record as migrated in this system
  # end
end
