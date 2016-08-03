class ReposController < ApplicationController
  before_action :set_repo, only: [:show, :edit, :update, :destroy, :checksum_log, :ingest, :review_status, :detect_metadata, :preview_xml_preview]

  def new
    binding.pry()
  end

  def create
    @repo = Repo.new
  end

  def show
    @message = @repo.create_remote
    redirect_to "#{root_url}admin_repo/repo/#{@repo.id}/git_actions", :flash => { @message.keys.first => @message.values.first }
  end

  def update
    if @repo.update(repo_params)
      redirect_to "#{root_url}admin_repo/repo/#{@repo.id}/git_actions", :flash => { :success => "Repo updated successfully."}
    else
      redirect_to "#{root_url}admin_repo/repo/#{@repo.id}/git_actions", :flash => { :error => "Repo was not updated successfully."}
    end
  end

  def checksum_log
    @message = Utils.generate_checksum_log("#{Utils.config.assets_path}/#{@repo.directory}")
    redirect_to "#{root_url}admin_repo/repo/#{@repo.id}/ingest", :flash => { @message.keys.first => @message.values.first }
  end

  def review_status
    @message = @repo.update(repo_params)
    redirect_to "#{root_url}admin_repo/repo/#{@repo.id}/ingest", :flash => { :success => "Review status note added." }
  end

  def preview_xml_preview
    @message = @repo.preview_xml_preview
    redirect_to "#{root_url}admin_repo/repo/#{@repo.id}/preview_xml", :flash => { @message.keys.first => @message.values.first }
  end

  def detect_metadata
    @message = @repo.detect_metadata_sources
    redirect_to "#{root_url}admin_repo/repo/#{@repo.id}/map_metadata", :flash => { @message.keys.first => @message.values.first }
  end


  private
    def set_repo
      @repo = Repo.find(params[:id])
    end

    def repo_params
      params[:repo][:review_status] = format_review_status(params[:repo][:review_status]) if params[:repo][:review_status].present?
      params.require(:repo).permit(:title, :directory, :identifier, :description, :metadata_subdirectory, :assets_subdirectory, :metadata_filename, :file_extensions, :version_control_agent, :preservation_filename, :review_status, :owner)
    end

    def format_review_status(message)
      message << " -- #{current_user.email} || #{Time.now}"
      return message
    end
end
