class MetadataSourcesController < ApplicationController

  layout 'application'

  before_action :set_metadata_source, only: [:show, :edit, :update]

  def show
  end

  def new
    @metadata_source = MetadataSource.new
  end

  def create
    @metadata_source = MetadataSource.new(metadata_source_params)
  end

  def edit
  end

  def update
    if @metadata_source.update(metadata_source_params)
      redirect_to "#{root_url}admin_repo/repo/#{@metadata_source.metadata_builder.repo.id}/generate_metadata", :flash => { :success => "Metadata source successfully updated." }
    else
      redirect_to "#{root_url}admin_repo/repo/#{@metadata_source.metadata_builder.repo.id}/generate_metadata", :flash => {:danger => @metadata_source.errors.full_messages }
    end
  end

  private

  def set_metadata_source
    @metadata_source = MetadataSource.find(params[:id])
  end

  def metadata_source_params
    params.require(:metadata_source).permit(:view_type, :num_objects, :x_start, :y_start, :x_stop, :y_stop, :original_mappings, :root_element, :parent_element, :user_defined_mappings, :children => [])
  end

end
