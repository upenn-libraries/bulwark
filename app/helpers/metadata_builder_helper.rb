module MetadataBuilderHelper


  def render_form_or_message
    if @object.metadata_builder.source.empty?
      render :partial => "metadata_builders/no_source"
    else
      render :partial => "metadata_builders/form", :locals => {metadata_builder: @object.metadata_builder}
    end
  end

end
