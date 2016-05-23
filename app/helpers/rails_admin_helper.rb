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

  def render_flash_errors
    error_list = ""
    flash[:error].each do |errors|
      errors.each do |e|
        error_list << content_tag("li", e)
      end
    end
    flash[:error] = content_tag("ul", error_list.html_safe).html_safe if flash.try(:error).present?
  end

  def refresh_metadata_from_source
    unless flash[:error]
      @object.metadata_builder.set_metadata_mappings
      @object.metadata_builder.save!
    end
  end

end
