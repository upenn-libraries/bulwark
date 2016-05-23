module MetadataSourceHelper

  def render_source_specs_form
    if @object.metadata_builder.metadata_source.present?
      render :partial => "metadata_sources/form"
    end
  end

  def render_metadata_generation_form
    if @object.metadata_builder.metadata_source.present?
      render :partial => "metadata_sources/generate_metadata"
    else
      render :partial => "metadata_sources/no_source"
    end
  end

  def refresh_metadata_from_source
    unless flash[:error]
      @object.metadata_builder.metadata_source.each do |source |
        source.set_metadata_mappings
        source.save!
        end
    end
  end

  def nested_relationships_values(parent_file)
    child_array = []
    child_candidates = []
    @object.metadata_builder.metadata_source.each do |source|
      child_candidates << source.path
    end
    child_candidates.delete_if{|x| x == parent_file}
    child_candidates.each do |child|
      child_array << [_prettify(child), child]
    end
    return child_array
  end

end
