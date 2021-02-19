class AdminController < ActionController::Base
  before_action :authenticate_user!

  layout 'admin'

  # ****This action should only be available for local development and test environments.****
  #
  # This action mimics the file download that would be available if the special remote
  # for development and test environments were S3.
  def special_remote_download
    if Bulwark::Config.special_remote[:type] == 'directory'
      glob_path = File.join(Bulwark::Config.special_remote[:directory], params[:bucket], '**', '**', params[:key], params[:key])
      path = Dir.glob(glob_path).first
      send_file(path, disposition: 'attachment')
    end
  end
end
