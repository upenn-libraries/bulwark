module CatalogHelper

  include Blacklight::CatalogHelperBehavior

  def render_catalog_show_preview(document)
    render :partial => "catalog/show_main_content_preview", :document => document
  end

end
