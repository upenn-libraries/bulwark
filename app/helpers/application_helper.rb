module ApplicationHelper

  include RailsAdmin::ApplicationHelper

  def render_image_list
    repo = Repo.where(:unique_identifier => @document.id).first
    images_to_render = repo.images_to_render
    content_tag(:div, '', id: 'pages', data: images_to_render.keys.to_json )
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



end
