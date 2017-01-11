module MetadataSourceHelper

  def render_source_specs_form
    if @object.metadata_builder.metadata_source.present?
      render :partial => 'metadata_sources/form'
    end
  end

  def render_source_type_form
    if @object.metadata_builder.metadata_source.present?
      render :partial => 'metadata_sources/type_form'
    end
  end

  def render_metadata_preview(source)
    accepted_types = %w(voyager structural_bibid bibliophilly bibliophilly_structural)
    if (accepted_types.include? source.source_type) && (source.user_defined_mappings.present?)
      heading_text_label = "colenda.metadata_sources.metadata_mapping.#{source.source_type}.heading"
      field_separator_label = "colenda.metadata_sources.metadata_mapping.#{source.source_type}.field_separator"
      mappings = ''
      metadata_preview = content_tag(:h2,t(heading_text_label))
      source.user_defined_mappings.each do |m,b|
        mappings << "<li>Entry #{m}#{t(field_separator_label)} #{render_value(b)}</li>"
        file_name = b['file_name'] unless b.is_a?(Array)
        if file_name.present? && @object.metadata_builder.last_file_checks.present?
          mappings << content_tag(:div, derivative_link(file_name), :class => 'preview_image')
        end
      end
      metadata_preview << content_tag(:ul, mappings.html_safe)
      content_tag(:div, metadata_preview.html_safe, :class => "#{source.source_type}-preview").html_safe
    end
  end

  def derivative_link(file_name)
    link_to(image_tag("#{Utils.config["federated_fs_path"]}/#{@object.names.directory}/#{@object.derivatives_subdirectory}/#{file_name}.thumb.jpeg"),"#{Utils.config["federated_fs_path"]}/#{@object.names.directory}/#{@object.derivatives_subdirectory}/#{file_name}.jpeg")
  end

  def render_value(value)
    return ap(value, :html => true) if value.is_a?(Hash)
    return value.join(', ') if value.is_a?(Array)
    return value
  end

  def render_warning_if_out_of_sync
    flash[:warning] =  t('colenda.warnings.out_of_sync.extraction') if @object.metadata_builder.metadata_source.any?{ |ms| ms.last_settings_updated > ms.last_extraction if ms.last_extraction.present? }
  end

  def nested_relationships_values(parent_file)
    child_array = []
    child_candidates = Hash.new
    @object.metadata_builder.metadata_source.pluck(:path, :id).each do |source|
      child_candidates[source.first] = source.last unless source.first == parent_file
    end
    child_candidates.each do |child|
      child_array << [prettify(child.first), child.last]
    end
    child_array
  end

end
