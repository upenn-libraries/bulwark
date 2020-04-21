module ManifestHelper

  def render_validate_manifest
    render :partial => 'manifests/validate_manifest'
  end

  def render_create_repos
    render :partial => 'manifests/create_repos'
  end

  def render_process_manifest
    render :partial => 'manifests/process_manifest'
  end

end
