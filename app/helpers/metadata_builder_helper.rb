module MetadataBuilderHelper

  def render_preview_xml
    if mappings_present?(:user_defined_mappings)
      render :partial => "metadata_builders/preview_xml"
    else
      render :partial => "metadata_builders/no_mappings"
    end
  end

  def render_source_select_form
    if @object.metadata_builder.qualified_metadata_files.present?
      render :partial => "metadata_builders/source_select"
    else
      render :partial => "metadata_builders/no_qualified_metadata_files"
    end
  end

  def render_sample_xml
    get_location = @object.version_control_agent.clone
    @object.version_control_agent.get(:get_location => get_location)
    @sample_xml_docs = ""
    @file_links = Array.new
    Dir.glob("#{get_location}/*.xml") do |file|
      if File.exist?(file)
        @file_links << link_to(prettify(file), "##{file}")
        anchor_tag = content_tag(:a, "", :name=> file)
        sample_xml_content = File.open(file, "r"){|io| io.read}
        sample_xml_doc = REXML::Document.new sample_xml_content
        sample_xml = ""
        sample_xml_doc.write(sample_xml, 1)
        header = content_tag(:h2, "XML Sample for #{prettify(file)}")
        xml_code = content_tag(:pre, "#{sample_xml}")
        @sample_xml_docs << content_tag(:div, anchor_tag << header << xml_code, :class => "doc")
      end
    end
    @object.version_control_agent.delete_clone
    @file_links_html = ""
    @file_links.each do |file_link|
      @file_links_html << content_tag(:li, file_link.html_safe)
    end
    return content_tag(:ul, @file_links_html.html_safe) << @sample_xml_docs.html_safe
  end

  def render_xml_warning_if_out_of_sync
    if @object.metadata_builder.last_xml_generated.present?
      flash[:warning] =  "Metadata has been updated since the last time this XML was generated.  Please press the button below to generate XML with the most current metadata." if @object.metadata_builder.metadata_source.any?{ |ms| @object.metadata_builder.last_xml_generated < ms.last_extraction if ms.last_extraction.present? }
    end
  end

  def prettify(file_path_input)
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
        raise "Invalid argument #{file_path_input}. prettify can only accept strings and arrays of strings."
      end
  end

  def mappings_present?(query_field)
     MetadataSource.where(:metadata_builder_id => @object.metadata_builder.id).pluck(query_field).all?{ |h| h.empty? } ? false : true
  end

  private

  def _prettified_working_file(file_path)
    file_array = file_path.split("/").reverse
    return "#{Utils.config[:object_data_path]}/#{file_array.second}/#{file_array.first}"
  end

end
