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
        mappings << "<li>#{t('colenda.metadata_sources.metadata_mapping.structural_entry')} #{m}#{t(field_separator_label)} #{render_value(b)}</li>"
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
    thumbnail_link = "#{Utils.config["federated_fs_path"]}/#{@object.names.directory}/#{@object.derivatives_subdirectory}/#{file_name}.thumb.jpeg"
    image_link = "#{Utils.config["federated_fs_path"]}/#{@object.names.directory}/#{@object.derivatives_subdirectory}/#{file_name}.jpeg"
    return link_to(image_tag(thumbnail_link), image_link) unless @object.problem_files["/#{@object.assets_subdirectory}/#{file_name}"].present?
    return @object.problem_files["/#{@object.assets_subdirectory}/#{file_name}"].present? ?  problem_warning(file_name).html_safe : ''
  end

  def problem_warning(file_name)
    content_tag :div, :class => 'inline-problem-files' do
      concat(t('colenda.metadata_sources.metadata_mapping.previews.issue_detected', :file_name => file_name))
      concat(content_tag(:span, "#{@object.problem_files["/#{@object.assets_subdirectory}/#{file_name}"]}", :class => 'issue'))
    end
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
