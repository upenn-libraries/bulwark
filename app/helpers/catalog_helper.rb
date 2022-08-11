require 'htmlentities'

module CatalogHelper
  include Blacklight::CatalogHelperBehavior

  def presenter_class
    BulwarkPresenter::DocumentPresenter
  end

  def thumbnail(document, options)
    thumbnail_location = document.fetch('thumbnail_location_ssi', nil)

    # Fetching from record if not present in Solr document.
    if thumbnail_location.nil?
      repo = Repo.find_by(unique_identifier: document.unique_identifier)
      thumbnail_location = repo&.thumbnail_location
    end

    return if thumbnail_location.blank?

    image_tag download_link(*thumbnail_location.split('/', 2))
  end

  def current_user?
    current_user != nil
  end

  def multivalue_no_separator(options={})
    options[:separator] = ' '
    html_entity(options)
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

  # Removing values that contain ID of this item because the are links back to this same page.
  def remove_circular_references(options = {})
    document = options[:document] # the original document
    value = options[:value] || [] # the value of the field

    value.delete_if {|v| v.include?(document[:id]) }
  end
end
