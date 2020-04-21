class ManifestsController < ApplicationController
  before_action :set_manifest, only: [:validate_manifest, :create_repos, :process_manifest]

  def new
  end

  def create
    @manifest = Manifest.new
  end

  def validate_manifest
    @job = ValidateManifestJob.perform_later(@manifest, root_url, current_user.email)
    initialize_job_activity('validate_manifest')
    redirect_to "#{root_url}admin_repo/manifest/#{@manifest.id}/validate_manifest", :flash =>  { :warning => t('colenda.manifests.validate_manifest.success') }
  end

  def create_repos
    @job = CreateReposJob.perform_later(@manifest, root_url, current_user.email)
    initialize_job_activity('create_repos')
    redirect_to "#{root_url}admin_repo/manifest/#{@manifest.id}/create_repos", :flash =>  { :warning => t('colenda.manifests.create_repos.success') }
  end

  def process_manifest
    @job = ProcessManifestJob.perform_later(@manifest, root_url, current_user.email)
    initialize_job_activity('process_manifest')
    redirect_to "#{root_url}admin_repo/manifest/#{@manifest.id}/process", :flash =>  { :warning => t('colenda.manifests.process_manifest.success') }
  end

  def initialize_job_activity(process)
    current_user.job_activity[@job.job_id] = { :unique_identifier => @manifest.unique_identifier, :manifest_name => @manifest.name, :process => process, :started => DateTime.now }
    current_user.save
  end

  private

  def set_manifest
    @manifest = Manifest.find(params[:id])
  end

  def manifest_params
    params.require(:manifest).permit(:uploaded_file)
  end

end
