module ApplicationHelper

  include RailsAdmin::ApplicationHelper

  def render_image_list
    repo = Repo.where(:unique_identifier => @document.id.reverse_fedorafy).first
    return content_tag(:div, '', id: 'pages', data: repo.images_to_render['iiif']['images'].to_json ) + render_openseadragon(repo)
  end

  def render_openseadragon(repo)
    return "<div id=\"openseadragon\" dir=\"#{resolve_reading_direction(repo.images_to_render['iiif']['reading_direction'])}\" style=\"width: 800px; height: 600px;\"></div>".html_safe
  end

  def resolve_reading_direction(reading_direction)
    return 'ltr' unless reading_direction.present?
    return 'ltr' if %w[left-to-right ltr].include?(reading_direction)
    return 'rtl' if %w[right-to-left rtl].include?(reading_direction)
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

end
