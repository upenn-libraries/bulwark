module ApplicationHelper

  include RailsAdmin::ApplicationHelper

  def render_image_list
    repo = Repo.where(:unique_identifier => @document.id.reverse_fedorafy).first
    rendered_keys = []
    repo.images_to_render.each do |key, value|
      rendered_keys << "#{public_fedora_path(key)}?width=#{value['width']}&height=#{value['height']}"
    end
    content_tag(:div, '', id: 'pages', data: rendered_keys.to_json )
  end

  def render_fedora_queue
    a = ''
    ids = Repo.where("queued").pluck(:id, :human_readable_name)
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

end
