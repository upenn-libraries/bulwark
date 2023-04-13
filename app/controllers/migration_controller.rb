# frozen_string_literal: true

class MigrationController < ActionController::Base
  # before_action :authenticate_token! # TODO: ???

  rescue_from 'ActiveRecord::RecordNotFound' do
    render json: { message: 'Record cannot be found' }, status: 404
  end

  rescue_from 'MigrationObjectBuilder::Error' do |exception|
    render json: { message: 'Problem generating serialized representation of repo',
                   exception: exception.message },
           status: 500
  end

  # TODO: check if already migrated?
  def serialize
    repo = Repo.find_by! unique_identifier: CGI.unescape(params[:id])
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
