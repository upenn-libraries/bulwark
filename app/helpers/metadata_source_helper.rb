module MetadataSourceHelper

  def render_source_specs_form(source)
    @source = source
    if @object.metadata_builder.metadata_source.present?
      render :partial => "metadata_sources/form", source: @source
    end
  end

  def render_source_type_form
    if @object.metadata_builder.metadata_source.present?
      render :partial => "metadata_sources/type_form"
    end
  end

  def render_metadata_form(source)
    @source = source
      case source.source_type
        when "custom"
          render :partial => "metadata_sources/generate_custom_metadata", :source => @source
        else "voyager"
          render :partial => "metadata_sources/voyager", :source => @source
      end
  end

  def render_warning_if_out_of_sync
    flash[:warning] =  "Metadata Source settings have been updated since the last extraction of metadata.  Please press the button below to extract metadata based on these new settings." if @object.metadata_builder.metadata_source.any?{ |ms| ms.last_settings_updated > ms.last_extraction }
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
    return child_array
  end

end
