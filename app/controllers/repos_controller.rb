class ReposController < ApplicationController
  before_action :set_repo, only: [:show, :edit, :update, :destroy, :checksum_log, :prepare_for_ingest, :ingest, :detect_metadata, :generate_xml_preview]

  def show
    @message = @repo.create_remote
    if @message[:error].present?
      redirect_to "#{root_url}admin_repo/repo/#{@repo.id}/git_review", :flash => { :error => @message[:error] }
    elsif @message[:success].present?
      redirect_to "#{root_url}admin_repo/repo/#{@repo.id}/git_review", :flash => { :success => @message[:success] }
    end
  end

  def checksum_log
    @message = Utils.generate_checksum_log("#{Utils.config.assets_path}/#{@repo.directory}")
    if @message[:error].present?
      redirect_to "#{root_url}admin_repo/repo/#{@repo.id}/preprocess", :flash => { :error => @message[:error] }
    elsif @message[:success].present?
      redirect_to "#{root_url}admin_repo/repo/#{@repo.id}/preprocess", :flash => { :success => @message[:success] }
    end
  end

  def ingest
    @message = Utils.fetch_and_convert_files
    if @message[:error].present?
      redirect_to "#{root_url}admin_repo/repo/#{@repo.id}/preprocess", :flash => { :error => @message[:error] }
    elsif @message[:success].present?
      redirect_to "#{root_url}admin_repo/repo/#{@repo.id}/preprocess", :flash => { :success => @message[:success] }
    end
  end

  # def ingest
  #   @message = Utils.import
  #   Utils.index
  #   if @message[:error].present?
  #     redirect_to "#{root_url}admin_repo/repo/#{@repo.id}/preprocess", :flash => { :error => @message[:error] }
  #   elsif @message[:success].present?
  #     redirect_to "#{root_url}admin_repo/repo/#{@repo.id}/preprocess", :flash => { :success => @message[:success] }
  #   end
  # end

  def generate_xml_preview
    @message = @repo.generate_xml_preview
    if @message[:error].present?
      redirect_to "#{root_url}admin_repo/repo/#{@repo.id}/generate_xml", :flash => { :error => @message[:error] }
    elsif @message[:success].present?
      redirect_to "#{root_url}admin_repo/repo/#{@repo.id}/generate_xml", :flash => { :success => @message[:success] }
    end
  end

  def detect_metadata
    @message = @repo.detect_metadata_sources
    if @message[:error].present?
      redirect_to "#{root_url}admin_repo/repo/#{@repo.id}/map_metadata", :flash => { :error => @message[:error] }
    elsif @message[:success].present?
      redirect_to "#{root_url}admin_repo/repo/#{@repo.id}/map_metadata", :flash => { :success => @message[:success] }
    end
  end


  private
    def set_repo
      @repo = Repo.find(params[:id])
    end

    def repo_params
      params.require(:repo).permit(:title, :directory, :identifier, :description, :metadata_subdirectory, :assets_subdirectory, :metadata_filename, :file_extensions, :version_control_agent)
    end
end
