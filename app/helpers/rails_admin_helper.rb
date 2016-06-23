require "rexml/document"

module RailsAdminHelper

  include CatalogHelper
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

  def render_review_box
    repo = Repo.where("ingested = ?", [@document.id].to_yaml).first!
    render_review_status(repo)
  end

end
