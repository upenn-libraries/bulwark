require 'htmlentities'

module CatalogHelper
  include Blacklight::CatalogHelperBehavior

  def presenter_class
    BulwarkPresenter::DocumentPresenter
  end

  def thumbnail(document, options)
    image_tag document.thumbnail_link
  end

  def html_entity(options={})
    separator = options[:separator].nil? ? '; ' : "#{options[:separator]}"
    option_vals = []
    options[:value].each do |val|
      option_vals << html_decode(display_render(val))
    end
    return option_vals.reject(&:blank?).join(separator)
  end

  def html_facet(facet_string)
    return html_decode(facet_string)
  end

  def display_render(string)
    transformations = { ',,' => ',', '&amp;' => '&', ':,' => ':', ' ;' => ';'}
    transformations.each_pair {|d,t| string = string.gsub(d, t)}
    string.html_safe
  end

  def html_decode(string_to_decode)
    decoder = HTMLEntities.new
    return decoder.decode(string_to_decode)
  end

  def render_admin_actions
    repo = Repo.find_by(unique_identifier: @document.unique_identifier)
    return unless repo.present?

    render 'admin_actions', repo: repo
  end

  def render_admin_link(repo)
    link = if repo.new_format
             admin_digital_object_path(repo)
           else
             "admin_repo/repo/#{repo.id}/ingest"
           end
    link_to('View in Colenda Admin', link)
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
