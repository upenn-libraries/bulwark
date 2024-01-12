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

  def render_audio_player
    repo = Repo.find_by(unique_identifier: @document.unique_identifier, new_format: true)
    return '' if repo.nil?

    assets = repo.assets.where(mime_type: ['audio/vnd.wave'])
    return '' if assets.blank?

    assets.map do |asset|
      render partial: 'other_display/audio', locals: { streaming_id: asset.filename, streaming_url: asset.access_file_link }
    end.join('').html_safe
  end

  # Rendering files that don't have a specific viewer that should be used. These files just get a download link.
  def render_other
    repo = Repo.find_by(unique_identifier: @document.unique_identifier, new_format: true)
    return '' if repo.nil?

    assets = repo.assets.where(mime_type: ['application/pdf', 'application/gzip'])
    return '' if assets.blank?

    ordered_files = repo.structural_metadata.user_defined_mappings['sequence'].map { |i| i['filename'] }
    assets = assets.sort_by { |a| ordered_files.index(a.filename) }

    render partial: 'other_display/file_download', locals: { assets: assets }
  end

  def render_uv
    repo = Repo.find_by(unique_identifier: @document.unique_identifier)
    partials = ''
    partials += render :partial => 'other_display/uv'
    return partials.html_safe if repo.has_images?
  end

  def render_iiif_manifest_link
    link = if @document.from_apotheca?
            @document.fetch('iiif_manifest_path_ss', nil) ? item_manifest_url(@document.unique_identifier) : nil
          else
            repo = Repo.find_by(unique_identifier: @document.unique_identifier)
            repo.has_images? ? "#{ENV['UV_URL']}/#{@document.id}/manifest" : nil
           end

    link ? link_to('IIIF presentation manifest', link) : nil
  end

  # @param [String] label
  def render_catalog_link(document, label: "Full Catalog Record (Franklin)")
    bibid = document.fetch('bibnumber_ssi', nil)

    if bibid.nil?
      repo = Repo.find_by(unique_identifier: document.unique_identifier)
      bibid = repo&.bibid
    end

    return if bibid.blank?

    link_to label, "https://franklin.library.upenn.edu/catalog/FRANKLIN_#{bibid}"
  end

  def additional_resources
    if @document.from_apotheca?
      @document.fetch(:iiif_manifest_path_ss, nil) || @document.fetch(:bibnumber_ssi, nil)
    else
      repo = Repo.find_by(unique_identifier: @document.unique_identifier)
      repo.bibid.present? || repo.has_images?
    end
  end

  def universal_viewer_path(document)
    url_args = "cv=#{params[:cv]}"

    if document.from_apotheca?
      "/uv/uv#?manifest=uv/uv#?manifest=#{manifest_item_url(document.unique_identifier)}&#{url_args}&config=/uv/uv-config.json"
    else
      # Add to this for additional UV params
      "/uv/uv#?manifest=uv/uv#?manifest=#{ENV['UV_URL']}/#{document.id}/manifest&#{url_args}&config=/uv/uv-config.json"
    end
  end
end
