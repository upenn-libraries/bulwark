# frozen_string_literal: true

class MigrationController < ActionController::Base
  # before_action :authenticate_token! # TODO: ???

  # rescue_from 'ActiveRecord::RecordNotFound' # TODO: handle
  # rescue_from 'MigrationObjectBuilder::Error' # TODO: handle

  # TODO: check if already migrated?
  def serialize
    repo = Repo.find_by unique_identifier: CGI.unescape(params[:id])
    migration_hash = MigrationObjectBuilder.new(repo).build
    render json: migration_hash.to_json # TODO: use Oj?
  end

  # def mark_migrated
  #   # TODO: Apotheca could POST here and we can mark the record as migrated in this system
  # end

  private

    def authenticate_token!
      true
    end
end
