module RepoHelper
  include Blacklight::BlacklightHelperBehavior
  def render_git_directions_or_actions
    full_path = "#{assets_path_prefix}/#{@object.directory}"
    if Dir.exists?(full_path)
      render :partial => "repos/git_directions", :locals => {:full_path => full_path}
    else
      render :partial => "repos/git_actions"
    end
  end

  def render_ingested_list
    render :partial => "repos/ingested_links"
  end

  def _generate_ingest_link(ingested_id)
    begin
      obj = ActiveFedora::Base.find(ingested_id)
      truncated_title = "#{obj.title.first[0..100]}..."
      return link_to(truncated_title, Rails.application.routes.url_helpers.catalog_url(obj, :only_path => true), :target => "_blank", :title => "Opens in a new  tab").html_safe
    rescue ActiveFedora::ObjectNotFoundError
      @object.ingested.delete(ingested_id)
      @object.save!
      return nil
    end
  end
end
