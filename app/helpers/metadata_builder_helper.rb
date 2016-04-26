module MetadataBuilderHelper

  def render_form_or_message(partial)
    if @object.metadata_builder.source.empty?
      render :partial => "metadata_builders/no_source"
    else
      render :partial => partial, :locals => {metadata_builder: @object.metadata_builder}
    end
  end

  def render_xml_or_message
    if @object.metadata_builder.field_mappings.present?
      render :partial => "metadata_builders/generate_xml"
    else
      render :partial => "metadata_builders/no_mappings"
    end
  end

  def render_ingest_or_message
    if @object.metadata_builder.preserve.present?
      render :partial => "metadata_builders/ingest_select"
    else
      render :partial => "metadata_builders/no_xml"
    end
  end

  def render_structure_or_not
    if @object.metadata_builder.preserve.present?
      render :partial => "metadata_builders/structure"
    end
  end

  def render_source_select_form
    render :partial => "metadata_builders/source_select"
  end

  def render_preserve_select_form
    render :partial => "metadata_builders/preserve_select"
  end

  def render_clear_out_form
    render :partial => "metadata_builders/clear_out"
  end

  def _structural_elements(file_name)
    root_default = ""
    child_default = ""
    if @object.metadata_builder.field_mappings.present?
      root_element = @object.metadata_builder.field_mappings[file_name]["root_element"]["mapped_value"].present? ? @object.metadata_builder.field_mappings[file_name]["root_element"]["mapped_value"] : root_default
      child_element = @object.metadata_builder.field_mappings[file_name]["child_element"]["mapped_value"].present? ? @object.metadata_builder.field_mappings[file_name]["child_element"]["mapped_value"] : child_default
      return root_element, child_element
    else
      return root_default, child_default
    end
  end

  def _nested_relationships_values(parent_file)
    child_array = Array.new
    child_candidates = _prettify(@object.metadata_builder.preserve)
    child_candidates.each do |child|
      child_array << [child, { parent_file => child }.to_s] unless _prettify(parent_file) == child
    end
    return child_array
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
