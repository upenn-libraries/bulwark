class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Blacklight::Base
  include HeaderAlert

  # base application layout is copied from Blacklight, with Matomo tracking added
  # https://github.com/projectblacklight/blacklight/blob/v5.13.0/app/views/layouts/blacklight.html.erb
  layout 'application'

  before_action :_set_current_user

  rescue_from ActiveRecord::RecordNotFound, :with => :rescue_not_found

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  # ****This action should only be available for local development and test environments.****
  #
  # This action mimics the file download that would be available if the special remote
  # for development and test environments were S3.
  def special_remote_download
    special_remote = Settings.digital_object.special_remote
    return unless special_remote.type == 'directory'

    glob_path = File.join(special_remote.directory, params[:bucket], '**', '**', params[:key], params[:key])
    path = Dir.glob(glob_path).first
    filename = params[:filename] + File.extname(params[:key]) if params[:filename].present?
    send_file(path, disposition: params[:disposition], filename: filename)
  end

  private
  def _set_current_user
    User.current = current_user.email if current_user
  end
end
