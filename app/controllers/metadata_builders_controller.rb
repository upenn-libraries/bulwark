class MetadataBuildersController < ApplicationController
  before_action :set_metadata_builder, only: [:edit, :update]
  before_filter :merge_mappings, :only => [:create, :update]


  def edit
    @metadata_builder = MetadataBuilder.find(params[:id])
  end

  def update
    @metadata_builder = MetadataBuilder.find(params[:id])
    if @metadata_builder.update(metadata_builder_params)
      flash[:success] = "Metadata Builder successfully updated"
      redirect_to "/admin_repo/repo/#{@metadata_builder.id}/map_metadata"
    else
      render :partial => "rails_admin/main/forms/map_metadata"
    end
  end

  private

  def set_metadata_builder
    @metadata_builder = MetadataBuilder.find(params[:id])
  end

  def metadata_builder_params
    params.require(:metadata_builder).permit(:parent_repo, :source, :field_mappings, :xml)
  end

  def merge_mappings
    params[:metadata_builder][:field_mappings] = params[:metadata_builder][:field_mappings].to_s
  end

end
