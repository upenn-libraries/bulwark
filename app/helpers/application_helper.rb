module ApplicationHelper

  include RailsAdmin::ApplicationHelper

  def render_image_list
    repo = Repo.where(:unique_identifier => @document.id).first
    images_to_render = repo.images_to_render
    content_tag(:div, "", id: "pages", data: images_to_render.keys.to_json )
  end

  def flash_class(level)
    case level
      when :notice then "alert alert-info"
      when :success then "alert alert-success"
      when :error then "alert alert-error"
      when :alert then "alert alert-error"
    end
  end

  def menu_for(parent, abstract_model = nil, object = nil, only_icon = false) # perf matters here (no action view trickery)
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

end
