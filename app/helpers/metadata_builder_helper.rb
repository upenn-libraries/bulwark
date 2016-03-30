module MetadataBuilderHelper

  def render_form_or_message(partial)
    if @object.metadata_builder.source.empty?
      render :partial => "metadata_builders/no_source"
    else
      render :partial => partial, :locals => {metadata_builder: @object.metadata_builder}
    end
  end

  def render_xml_or_message
    if @object.metadata_builder.field_mappings.nil?
      render :partial => "metadata_builders/no_mappings"
    else
      render :partial => "metadata_builders/generate_xml"
    end
  end

  def render_parent_child_form(form, file_name)
    form.label "field_mappings[#{file_name}][root_element][mapped_value]", "Root element:"
    form.text_field "field_mappings[#{file_name}][root_element][mapped_value]", :value => "thing"
    content_tag(:div, form.submit, :class => "form-bottom")
    return form
  end

  def _structural_elements(file_name)
    root_default = "record"
    child_default = ""
    if @object.metadata_builder.field_mappings.present?
      root_element = @object.metadata_builder.field_mappings[file_name]["root_element"]["mapped_value"].present? ? @object.metadata_builder.field_mappings[file_name]["root_element"]["mapped_value"] : root_default
      child_element = @object.metadata_builder.field_mappings[file_name]["child_element"]["mapped_value"].present? ? @object.metadata_builder.field_mappings[file_name]["child_element"]["mapped_value"] : child_default
      return root_element, child_element
    else
      return root_default, child_default
    end
  end

  def _prettify(file_path_input)
      if file_path_input.is_a? Array
        file_path_array = Array.new
        file_path_input.each do |file_path|
          file_path_array << _prettified_working_file(file_path)
        end
        return file_path_array
      elsif file_path_input.is_a? String
        file_path_string = _prettified_working_file(file_path_input)
        return file_path_string
      else
        raise "Invalid argument #{file_path_input}. _prettify can only accept strings and arrays of strings."
      end
  end

  def _prettified_working_file(file_path)
    return file_path.gsub(@object.version_control_agent.working_path, "")
  end

end
