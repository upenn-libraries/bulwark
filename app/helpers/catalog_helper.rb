module CatalogHelper

  include Blacklight::CatalogHelperBehavior

  def render_catalog_show_preview
    render :partial => "catalog/show_main_content_preview"
  end

end
