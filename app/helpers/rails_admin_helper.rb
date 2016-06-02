require "rexml/document"

module RailsAdminHelper

  include MetadataBuilderHelper
  include MetadataSourceHelper
  include RepoHelper
  include Filesystem
  include Utils

  def render_git_remote_options
    render_git_directions_or_actions
  end

  def render_ingest_select_form
    render_ingest_or_message
  end

  def render_ingest_links
    render_ingested_list
  end

  def _metadata_builder(repo)
    mb = MetadataBuilder.where(:parent_repo => repo.id).blank? ? MetadataBuilder.create(:parent_repo => repo.id) : MetadataBuilder.find_by(:parent_repo => repo.id)
    return mb
  end

end
