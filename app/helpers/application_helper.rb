module ApplicationHelper
  include DOTIW::Methods # makes distance_of_time helper available in views

  def render_featured_list
    items = ''
    Dir.glob("#{Rails.root}/public/assets/featured/manifests/*.yml").each do |manifest|
      data = YAML.load(File.read(manifest))
      text_link = link_to(data[:title], data[:link])
      image = image_tag("/assets/featured/#{data[:filename]}", :alt => data[:title])
      image_link =  link_to(image.html_safe, data[:link])
      span = content_tag(:span, text_link)
      link_div = content_tag(:div, span, {:class => 'bx-caption'})
      item_contents = link_div + image_link
      featured_item = content_tag(:li, item_contents, {:title => data[:title]})
      items << featured_item
    end
    return items.html_safe
  end

  def render_iiif_manifest_link
    # Check to make sure iiif manifest is present in storage.
    return unless @document.iiif_manifest?

    link_to 'IIIF presentation manifest', item_manifest_url(@document.unique_identifier)
  end

  # @param [String] label
  def render_catalog_link(document, label: "Full Catalog Record")
    return unless document.bibnumber?

    link_to label, "https://find.library.upenn.edu/catalog/#{document.bibnumber}"
  end

  def additional_resources
    @document.iiif_manifest? || @document.bibnumber?
  end

  def universal_viewer_path(document)
    url_args = "cv=#{params[:cv]}"

    "/uv/uv#?manifest=uv/uv#?manifest=#{manifest_item_url(document.unique_identifier)}&#{url_args}&config=/uv/uv-config.json"
  end
end
