module MetadataBuilderHelper

  def render_form_or_message(partial)
    if @object.metadata_builder.source.present?
      render :partial => partial, :locals => {metadata_builder: @object.metadata_builder}
    else
      render :partial => "metadata_builders/no_source"
    end
  end

  def render_preview_xml
    if @object.metadata_builder.preserve.present?
      render :partial => "metadata_builders/preview_xml"
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

  def render_source_select_form
    if @object.metadata_builder.available_metadata_files.present?
      render :partial => "metadata_builders/source_select"
    else
      render :partial => "metadata_builders/no_available_metadata_files"
    end
  end

  def render_sample_xml
    @object.version_control_agent.clone
    @object.version_control_agent.get(:get_location => "#{@object.version_control_agent.working_path}/#{@object.metadata_subdirectory}")
    @sample_xml_docs = ""
    @file_links = Array.new
    @object.metadata_builder.preserve.each do |file_name|
      file = "#{@object.version_control_agent.working_path}/#{@object.metadata_subdirectory}/#{file_name}"
      @file_links << link_to(_prettify(file), "##{file}")
      anchor_tag = content_tag(:a, "", :name=> file)
      sample_xml_content = File.open(file, "r"){|io| io.read}
      sample_xml_doc = REXML::Document.new sample_xml_content
      sample_xml = ""
      sample_xml_doc.write(sample_xml, 1)
      header = content_tag(:h3, "XML Sample for #{_prettify(file)}")
      xml_code = content_tag(:pre, "#{sample_xml}")
      @sample_xml_docs << content_tag(:div, anchor_tag << header << xml_code, :class => "doc")
    end
    @object.version_control_agent.delete_clone
    @file_links_html = ""
    @file_links.each do |file_link|
      @file_links_html << content_tag(:li, file_link.html_safe)
    end
    return content_tag(:ul, @file_links_html.html_safe) << @sample_xml_docs.html_safe
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
