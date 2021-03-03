module ApplicationHelper

  include RailsAdmin::ApplicationHelper

  # Doesn't seem to be used?
  def render_image_list
    repo = Repo.where(:unique_identifier => @document.id.reverse_fedorafy).first
    return '' unless repo.present? && repo.images_to_render.present?
    images_list = repo.images_to_render['iiif'].present? ? repo.images_to_render['iiif']['images'] : legacy_image_list(repo)
    return content_tag(:div, '', id: 'pages', data: images_list.to_json ) + render_openseadragon(repo)
  end

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

  def render_collection_names_hash
    collections_hash = Hash.new(0)
    solr_url = ENV['PROD_SOLR_URL'].present? ? ENV['PROD_SOLR_URL'] : 'http://localhost:8983/solr/blacklight-core'
    collections_url = "#{solr_url}/select?q=*%3A*&fq=-active_fedora_model_ssi%3AImage&fq=-active_fedora_model_ssi%3ACollection&fq=-active_fedora_model_ssi%3A%22ActiveFedora%3A%3ADirectContainer%22&fq=-active_fedora_model_ssi%3A%22ActiveFedora%3A%3AIndirectContainer%22&fq=-active_fedora_model_ssi%3A%22ActiveFedora%3A%3AAggregation%3A%3AProxy%22&rows=0&indent=true&facet=true&facet.field=collection_sim&facet.limit=-1&wt=json"
    collections_uri = URI(collections_url)
    collections_response = Net::HTTP.get(collections_uri)
    JSON.parse(collections_response)['facet_counts']['facet_fields']['collection_sim'].each_slice(2) do |value|
      collections_hash[value.first] = value.last if value.last >= 5
    end
    no_coll_url = "#{solr_url}/select?q=-collection_sim%3A*&fq=-active_fedora_model_ssi%3AImage&fq=-active_fedora_model_ssi%3ACollection&fq=-active_fedora_model_ssi%3A%22ActiveFedora%3A%3ADirectContainer%22&fq=-active_fedora_model_ssi%3A%22ActiveFedora%3A%3AIndirectContainer%22&fq=-active_fedora_model_ssi%3A%22ActiveFedora%3A%3AAggregation%3A%3AProxy%22&rows=0&fl=collection_sim&wt=json&indent=true"
    no_coll_uri = URI(no_coll_url)
    no_coll_response = Net::HTTP.get(no_coll_uri)
    collections_hash['No collection'] = JSON.parse(no_coll_response)['response']['numFound']
    return collections_hash
  end

  def render_ingested_hash
    ingested_hash = Hash.new(0)
    batches = Batch.where(:status => "complete", :updated_at => 14.days.ago..0.days.ago)
    batches.each do |batch|
      ingested_hash[batch.updated_at.to_date] += batch.queue_list.count
    end
    return ingested_hash
  end

  def render_ableplayer
    repo = Repo.where(:unique_identifier => @document.id.reverse_fedorafy).first
    partials = ''
    return '' unless repo.present?
    repo.file_display_attributes.each do |key, value|
       partials += render :partial => 'av_display/audio', :locals => {:streaming_id => key, :streaming_url => value[:streaming_url]} if value[:content_type] == 'mp3'
       partials += render :partial => 'av_display/video', :locals => {:streaming_id => key, :streaming_url => value[:streaming_url]} if value[:content_type] == 'mp4'
    end
    return partials.html_safe
  end

  def render_warc
    repo = Repo.where(:unique_identifier => @document.id.reverse_fedorafy).first
    partials = ''
    return '' unless repo.present?
    repo.file_display_attributes.each do |key, value|
      partials += render :partial => 'other_display/warc', :locals => {:download_url => value[:download_url].gsub("#{Utils::Storage::Ceph.config.protocol}#{Utils::Storage::Ceph.config.host}",''), :filename => value[:filename]} if value[:content_type] == 'gz'
    end
    return partials.html_safe
  end

  def render_pdf
    repo = Repo.find_by(unique_identifier: @document.id.reverse_fedorafy, new_format: true)
    return '' if repo.nil?

    assets = repo.assets.where(mime_type: 'application/pdf')
    return '' if assets.blank?

    ordered_files = repo.structural_metadata.user_defined_mappings['sequence'].map { |i| i['filename'] }
    assets = assets.sort_by { |a| ordered_files.index(a.filename) }

    render partial: 'other_display/file_download', locals: { assets: assets }
  end

  def render_uv
    repo = Repo.find_by(unique_identifier: @document.id.reverse_fedorafy)
    partials = ''
    partials += render :partial => 'other_display/uv'
    return partials.html_safe if repo.has_images?
  end

  def render_iiif_manifest_link
    repo = Repo.where(:unique_identifier => @document.id.reverse_fedorafy).first
    return repo.has_images? ? link_to("IIIF presentation manifest", "#{ENV['UV_URL']}/#{@document.id}/manifest") : ''
  end

  def render_catalog_link
    repo = Repo.find_by(unique_identifier: @document.id.reverse_fedorafy)
    return repo.bibid.present? ? link_to("Franklin record", "https://franklin.library.upenn.edu/catalog/FRANKLIN_#{validate_bib_id(repo.bibid)}") : ''
  end

  def additional_resources
    repo = Repo.find_by(unique_identifier: @document.id.reverse_fedorafy)
    return true if repo.bibid.present? || repo.has_images?
  end

  def validate_bib_id(bib_id)
    return bib_id.to_s.length <= 7 ? "99#{bib_id}3503681" : bib_id.to_s
  end

  def universal_viewer_path(identifier)
    # Add to this for additional UV params
    url_args = "cv=#{params[:cv]}"
    "/uv/uv#?manifest=uv/uv#?manifest=#{ENV['UV_URL']}/#{identifier}/manifest&#{url_args}&config=/uv/uv-config.json"
  end

    def render_reviewed_queue
    a = ''
    ids = Repo.where('queued' => 'ingest').pluck(:id, :human_readable_name)
    a = 'Nothing approved waiting for batching' if ids.length == 0
    ids.each do |id|
      a << content_tag(:li,link_to(id[1], "#{Rails.application.routes.url_helpers.rails_admin_url(:only_path => true)}/repo/#{id[0]}/ingest"))
    end
    return content_tag(:ul, a.html_safe)
  end

  def render_fedora_queue
    a = ''
    ids = Repo.where('queued' => 'fedora').pluck(:id, :human_readable_name)
    a = 'Nothing in the queue' if ids.length == 0
    ids.each do |id|
      a << content_tag(:li,link_to(id[1], "#{Rails.application.routes.url_helpers.rails_admin_url(:only_path => true)}/repo/#{id[0]}/ingest"))
    end
    return content_tag(:ul, a.html_safe)
  end

  def flash_class(level)
    case level
      when :notice then 'alert alert-info'
      when :success then 'alert alert-success'
      when :error then 'alert alert-error'
      when :alert then 'alert alert-error'
      else 'alert alert-info'
    end
  end

  def menu_for(parent, abstract_model = nil, object = nil, only_icon = false)
    actions = actions(parent, abstract_model, object).select { |a| a.http_methods.include?(:get) }
    actions.collect do |action|
      wording = wording_for(:menu, action)
      %(
          <li title="#{wording if only_icon}" rel="#{'tooltip' if only_icon}" class="icon #{action.key}_#{parent}_link #{'active' if current_action?(action)}">
            <a class="#{action.pjax? ? 'pjax' : ''}" href="#{rails_admin.url_for(action: action.action_name, controller: 'rails_admin/main', model_name: abstract_model.try(:to_param), id: (object.try(:persisted?) && object.try(:id) || nil))}">
              <i class="#{action.link_icon}"></i>
              <div class="wording">#{wording}</div>
            </a>
          </li>
        )
    end.join.html_safe
  end

  def public_fedora_path(path)
    # TODO: Turn env var into config option?
    if ENV['PUBLIC_FEDORA_URL'].present?
      fedora_yml = "#{Rails.root}/config/fedora.yml"
      fedora_config = YAML.load(ERB.new(File.read(fedora_yml)).result)[Rails.env]
      fedora_link = "#{fedora_config['url']}#{fedora_config['base_path']}"
      return path.gsub(fedora_link, ENV['PUBLIC_FEDORA_URL'])
    else
      return path
    end
  end

  def legacy_image_list(repo)
    display_array = []
    repo.metadata_builder.get_structural_filenames.each do |filename|
      entry = repo.file_display_attributes.select{|key, hash| hash[:file_name].split('/').last == "#{filename}.jpeg"}
      display_array << entry.keys.first
    end
    return display_array.map{|k|"#{Display.config['iiif']['image_server']}#{repo.names.bucket}%2F#{k}/info.json"}

  end

  def legacy_reading_direction(repo)
    return repo.images_to_render.first.present? ? repo.images_to_render.first[1]['reading_direction'].first : 'left-to-right'
  end

end
