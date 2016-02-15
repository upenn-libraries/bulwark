class MetadataBuildersController < ApplicationController
  before_action :set_metadata_builder, only: [:edit, :update]

  def edit
    @metadata_builder = MetadataBuilder.find(params[:id])
  end

  def update
    @metadata_builder = MetadataBuilder.find(params[:id])
    if metadata_builder.update_attributes(metadata_builder_params)
      flash[:success] = "Hooray successful update!"
      redirect_to "/admin_repo/repo/#{@metadata_builder.id}/map_metadata"
    else
      render 'edit'
    end
  end

  private

  def metadata_builder_params
    params.require(:parent_repo, :source).permit(:field_mappings, :xml)
  end

end
