module ApplicationHelper

  include RailsAdmin::ApplicationHelper

  def osd_nav_images
    nav_images = {
        zoomIn: {
            REST:      image_path('openseadragon/zoomin_rest.png'),
            GROUP:     image_path('openseadragon/zoomin_grouphover.png'),
            HOVER:     image_path('openseadragon/zoomin_hover.png'),
            DOWN:      image_path('openseadragon/zoomin_pressed.png')
        },
        zoomOut: {
            REST:    image_path('openseadragon/zoomout_rest.png'),
            GROUP:   image_path('openseadragon/zoomout_grouphover.png'),
            HOVER:   image_path('openseadragon/zoomout_hover.png'),
            DOWN:    image_path('openseadragon/zoomout_pressed.png')
        },
        home: {
            REST:    image_path('openseadragon/home_rest.png'),
            GROUP:   image_path('openseadragon/home_grouphover.png'),
            HOVER:   image_path('openseadragon/home_hover.png'),
            DOWN:    image_path('openseadragon/home_pressed.png')
        },
        fullpage: {
            REST:    image_path('openseadragon/fullpage_rest.png'),
            GROUP:   image_path('openseadragon/fullpage_grouphover.png'),
            HOVER:   image_path('openseadragon/fullpage_hover.png'),
            DOWN:    image_path('openseadragon/fullpage_pressed.png')
        },
        rotateleft: {
            REST:    image_path('openseadragon/rotateleft_rest.png'),
            GROUP:   image_path('openseadragon/rotateleft_grouphover.png'),
            HOVER:   image_path('openseadragon/rotateleft_hover.png'),
            DOWN:    image_path('openseadragon/rotateleft_pressed.png')
        },
        rotateright: {
            REST:    image_path('openseadragon/rotateright_rest.png'),
            GROUP:   image_path('openseadragon/rotateright_grouphover.png'),
            HOVER:   image_path('openseadragon/rotateright_hover.png'),
            DOWN:    image_path('openseadragon/rotateright_pressed.png')
        },
        previous: {
            REST:    image_path('openseadragon/previous_rest.png'),
            GROUP:   image_path('openseadragon/previous_grouphover.png'),
            HOVER:   image_path('openseadragon/previous_hover.png'),
            DOWN:    image_path('openseadragon/previous_pressed.png')
        },
        next: {
            REST:    image_path('openseadragon/next_rest.png'),
            GROUP:   image_path('openseadragon/next_grouphover.png'),
            HOVER:   image_path('openseadragon/next_hover.png'),
            DOWN:    image_path('openseadragon/next_pressed.png')
        }
    }
    return content_tag(:div, '', id: 'navImages', data: nav_images.to_json)
  end

  def render_image_list
    repo = Repo.where(:unique_identifier => @document.id.reverse_fedorafy).first
    return '' unless repo.present? && repo.images_to_render.present?
    images_list = repo.images_to_render['iiif'].present? ? repo.images_to_render['iiif']['images'] : legacy_image_list(repo)
    return content_tag(:div, '', id: 'pages', data: images_list.to_json ) + render_openseadragon(repo)
  end

  def render_openseadragon(repo)
    return "<div id=\"openseadragon\" dir=\"#{resolve_reading_direction(repo)}\" style=\"width: 800px; height: 600px;\"></div>".html_safe
  end

  def resolve_reading_direction(repo)
    reading_direction = repo.images_to_render['iiif'].present? ? repo.images_to_render['iiif']['reading_direction'] : legacy_reading_direction(repo)
    return 'ltr' unless reading_direction.present?
    return 'ltr' if %w[left-to-right ltr].include?(reading_direction)
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
