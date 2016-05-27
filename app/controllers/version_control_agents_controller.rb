class VersionControlAgentsController < ApplicationController

  def new
    @version_control_agent = VersionControlAgent.new(version_control_agent_params)
  end

  private
    def _set_version_control_agent
      @version_control_agent = VersionControlAgent.find(params[:id])
    end

    def version_control_agent_params
      params.permit(:vc_type, :remote_repo_path, :working_repo_path, :repo)
    end

end
