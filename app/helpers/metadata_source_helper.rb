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
    if prepared_metadata?(source)
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

  def render_files_preview(source)
    return unless prepared_structural?(source)
    source_file_preview = ''
    source.user_defined_mappings.each do |key, value_hash|
      file_name = "<div class=\"file-name\">#{"".html_safe + value_hash[source.file_field]}</div>".html_safe
      derivative = derivative_link(value_hash[source.file_field],'filename_thumb_preview')
      source_file_preview << "<li>#{derivative + file_name}</li>"
    end
    sources_preview = "<ul>#{source_file_preview}</ul>"
    return sources_preview.present? ? "<div class=\"preview-thumbnails\">#{sources_preview}</div>".html_safe : ""
  end

  def derivative_link(file_name, derivative_type = 'page_preview')
    thumb_key = get_key_by_filename("#{@object.derivatives_subdirectory}/#{file_name}.thumb.jpeg")
    preview_key = get_key_by_filename("#{@object.derivatives_subdirectory}/#{file_name}.jpeg")
    thumbnail_link = Utils::Process.read_storage_link(thumb_key, @object)
    preview_link = Utils::Process.read_storage_link(preview_key, @object)
    return problem_warning(file_name, derivative_type).html_safe if @object.problem_files["/#{@object.assets_subdirectory}/#{file_name}"].present?
    return link_to(image_tag(thumbnail_link), preview_link) if derivative_type == 'page_preview'
    return link_to(image_tag(thumbnail_link, width: '120', :alt => file_name,  :title => file_name), preview_link) if derivative_type == 'filename_thumb_preview'

  end

  def get_key_by_filename(file_name)
    key = ''
    @object.file_display_attributes.each do |k, v|
      key =  k if v.rassoc(file_name).try(:last).present?
    end
    return key
  end

  def problem_warning(file_name, warning_type = 'page_preview')
    return "<div class=\"inline-problem-files\">#{t('colenda.metadata_sources.metadata_mapping.previews.issue_detected', :file_name => file_name)}<span class=\"issue\">#{@object.problem_files["/#{@object.assets_subdirectory}/#{file_name}"]}</span></div>" if warning_type == 'page_preview'
    return "<div class=\"issue\">#{@object.problem_files["/#{@object.assets_subdirectory}/#{file_name}"]}</div>" if warning_type == 'filename_thumb_preview'
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

  def prepared_metadata?(source)
    accepted_types = %w(voyager structural_bibid bibliophilly bibliophilly_structural)
    return true if (accepted_types.include? source.source_type) && (source.user_defined_mappings.present?)
    return false
  end

  def prepared_descriptive?(source)
    accepted_types = %w(voyager bibliophilly)
    return true if (accepted_types.include? source.source_type) && (source.user_defined_mappings.present?)
    return false
  end

  def prepared_structural?(source)
    accepted_types = %w(structural_bibid bibliophilly_structural)
    return true if (accepted_types.include? source.source_type) && (source.user_defined_mappings.present?)
    return false
  end

end
