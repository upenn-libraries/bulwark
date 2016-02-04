class ReposController < ApplicationController
  before_action :set_repo, only: [:show, :edit, :update, :destroy, :checksum_log, :prepare_for_ingest, :ingest]

  def index
    @repos = Repo.all
  end

  def show
    @message = @repo.create_remote
    if @message[:error].present?
      redirect_to "/admin_repo/repo/#{@repo.id}/git_review", :flash => { :error => @message[:error] }
    elsif @message[:success].present?
      redirect_to "/admin_repo/repo/#{@repo.id}/git_review", :flash => { :success => @message[:success] }
    end
  end

  def new
    @repo = Repo.new
  end

  def edit
  end

  def create
    @repo = Repo.new(repo_params)

    respond_to do |format|
      if @repo.save
        format.html { redirect_to @repo, notice: 'Repo was successfully created.' }
        format.json { render :show, status: :created, location: @repo }
      else
        format.html { render :new }
        format.json { render json: @repo.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @repo.update(repo_params)
        format.html { redirect_to @repo, notice: 'Repo was successfully updated.' }
        format.json { render :show, status: :ok, location: @repo }
      else
        format.html { render :edit }
        format.json { render json: @repo.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @repo.destroy
    respond_to do |format|
      format.html { redirect_to repos_url, notice: 'Repo was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def checksum_log
    @message = Utils.generate_checksum_log("#{Utils.config.assets_path}/#{@repo.directory}")
    if @message[:error].present?
      redirect_to "/admin_repo/repo/#{@repo.id}/preprocess", :flash => { :error => @message[:error] }
    elsif @message[:success].present?
      redirect_to "/admin_repo/repo/#{@repo.id}/preprocess", :flash => { :success => @message[:success] }
    end
  end

  def prepare_for_ingest
    @message = Utils.fetch_and_convert_files
    if @message[:error].present?
      redirect_to "/admin_repo/repo/#{@repo.id}/preprocess", :flash => { :error => @message[:error] }
    elsif @message[:success].present?
      redirect_to "/admin_repo/repo/#{@repo.id}/preprocess", :flash => { :success => @message[:success] }
    end
  end

  def ingest
    @message = Utils.import
    Utils.index
    if @message[:error].present?
      redirect_to "/admin_repo/repo/#{@repo.id}/preprocess", :flash => { :error => @message[:error] }
    elsif @message[:success].present?
      redirect_to "/admin_repo/repo/#{@repo.id}/preprocess", :flash => { :success => @message[:success] }
    end
  end

  private
    def set_repo
      @repo = Repo.find(params[:id])
    end

    def repo_params
      params.require(:repo).permit(:title, :directory, :identifier, :description, :metadata_subdirectory, :assets_subdirectory, :metadata_filename, :file_extensions)
    end
end
