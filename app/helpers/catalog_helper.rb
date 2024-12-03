module CatalogHelper
  include Blacklight::CatalogHelperBehavior

  def presenter_class
    BulwarkPresenter::DocumentPresenter
  end

  def thumbnail(document, options)
    image_tag document.thumbnail_link(root_url)
  end

  def display_render(string)
    transformations = { ',,' => ',', '&amp;' => '&', ':,' => ':', ' ;' => ';'}
    transformations.each_pair {|d,t| string = string.gsub(d, t)}
    string.html_safe
  end

  # Additional URL helpers needed for item and asset urls because the built-in methods escape the ARK.
  def item_manifest_url(unique_identifier)
    "#{root_url}items/#{unique_identifier}/manifest"
  end

  def asset_thumbnail_url(unique_identifier, id)
    "#{root_url}items/#{unique_identifier}/assets/#{id}/thumbnail"
  end

  def asset_original_url(unique_identifier, id)
    "#{root_url}items/#{unique_identifier}/assets/#{id}/original"
  end

  def asset_access_url(unique_identifier, id)
    "#{root_url}items/#{unique_identifier}/assets/#{id}/access"
  end
end
