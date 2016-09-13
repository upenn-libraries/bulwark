class MetadataSourcesController < ApplicationController

  layout 'application'

  def new
    @metadata_source = MetadataSource.new
  end

  def create
    @metadata_source = MetadataSource.new(metadata_source_params)
  end

  private

  def set_metadata_source
    @metadata_source = MetadataSource.find(params[:id])
  end

  def metadata_source_params
    params.require(:metadata_source).permit(:view_type, :num_objects, :x_start, :y_start, :x_stop, :y_stop, :original_mappings, :root_element, :parent_element, :user_defined_mappings, :children => [])
  end

end
