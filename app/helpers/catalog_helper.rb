module CatalogHelper

  include Blacklight::CatalogHelperBehavior

  def render_catalog_show_preview
    render :partial => 'catalog/show_main_content_preview'
  end

  def thumbnail(document, options)
    default = content_tag(:div, '', :class => 'glyphicon glyphicon-book', 'aria-hidden' => 'true').html_safe
    thumbnail_url = public_fedora_path("#{ActiveFedora::Base.where(:id => document.id).first.thumbnail_link}")
    Repo.where(:unique_identifier => document.id.reverse_fedorafy).pluck(:thumbnail).first ? image_tag(thumbnail_url) : default
  end

  def current_user?
    current_user != nil
  end

end
