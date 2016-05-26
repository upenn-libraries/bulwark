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
    child_candidates = Hash.new
    MetadataSource.pluck(:path, :id).each do |source|
      child_candidates[source.first] = source.last unless source.first == parent_file
    end
    child_candidates.each do |child|
      child_array << [_prettify(child.first), child.last]
    end
    return child_array
  end

  def render_flash_errors
    error_list = ""
    flash[:error].each do |errors|
      errors.each do |e|
        error_list << content_tag("li", e)
      end
    end
    flash[:error] = content_tag("ul", error_list.html_safe).html_safe if flash.try(:error).present?
  end

end
