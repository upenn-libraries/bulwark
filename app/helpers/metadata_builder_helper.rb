module MetadataBuilderHelper

  def render_preview_xml
    if mappings_present?(:user_defined_mappings)
      render :partial => 'metadata_builders/preview_xml'
    else
      render :partial => 'metadata_builders/no_mappings'
    end
  end

  def render_source_select_form
    if @object.metadata_builder.qualified_metadata_files.present?
      render :partial => 'metadata_builders/source_select'
    else
      render :partial => 'metadata_builders/no_qualified_metadata_files'
    end
  end

  def render_sample_xml
    @object.metadata_builder.xml_preview.html_safe if @object.metadata_builder.xml_preview.present?
  end

  def render_xml_warning_if_out_of_sync
    if @object.metadata_builder.last_xml_generated.present?
      flash[:warning] =  t('colenda.warnings.out_of_sync.xml') if @object.metadata_builder.metadata_source.any?{ |ms| @object.metadata_builder.last_xml_generated < ms.last_extraction if ms.last_extraction.present? }
    end
  end

  def render_file_checks_info
    "#{"No known problems detected -- " if @object.problem_files.empty?} File checks last completed at #{content_tag(:span, @object.metadata_builder.last_file_checks.strftime('%I:%M%p, %a %b %d, %Y '), :class => 'last-file-checks')}".html_safe if @object.metadata_builder.last_file_checks.present?
  end

  def prettify(file_path_input)
      if file_path_input.is_a? Array
        file_path_array = Array.new
        file_path_input.each do |file_path|
          file_path_array << _prettified_working_file(file_path)
        end
        file_path_array
      elsif file_path_input.is_a? String
        _prettified_working_file(file_path_input)
      else
        raise t('colenda.warnings.invalid_prettify_argument', :argument => file_path_input)
      end
  end

  def mappings_present?(query_field)
     MetadataSource.where(:metadata_builder_id => @object.metadata_builder.id).pluck(query_field).all?{ |h| h.empty? } ? false : true
  end

  private

  def _prettified_working_file(file_path)
    file_array = file_path.split('/').reverse
    "#{Utils.config[:object_data_path]}/#{file_array.second}/#{file_array.first}"
  end

end
