module CatalogHelper

  include Blacklight::CatalogHelperBehavior

  def render_catalog_show_preview
    render :partial => "catalog/show_main_content_preview"
  end

  def thumbnail(document, options)
    image_tag "#{ActiveFedora::Base.where(:id => document.id).first.thumbnail_link}", :width => 100, :height => 150
  end

  def current_user?
    current_user != nil
  end

end
