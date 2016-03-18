class MetadataBuildersController < ApplicationController

  before_action :set_metadata_builder, only: [:edit, :update, :git_annex_commit]
  before_filter :merge_mappings, :only => [:create, :update]
  before_filter :merge_xml, :only => [:create, :update]
  before_filter :build_xml, :only => [:create, :update]

  def edit
  end

  def update
    if @metadata_builder.update(metadata_builder_params)
      flash[:success] = "Metadata Builder successfully updated"
      redirect_to "/admin_repo/repo/#{@metadata_builder.id}/map_metadata"
    else
      render :partial => "rails_admin/main/forms/map_metadata"
    end
  end

  def git_annex_commit
    @message = @metadata_builder.commit_to_annex
    if @message[:error].present?
      redirect_to "admin_repo/", :flash => { :error => @message[:error] }
    elsif @message[:success].present?
      redirect_to "admin_repo/", :flas => { :success => @message[:success] }
    end

  end


  private

  def set_metadata_builder
    @metadata_builder = MetadataBuilder.find(params[:id])
  end

  def metadata_builder_params
    params.require(:metadata_builder).permit(:parent_repo, :source, :source_mappings, :field_mappings, :xml)
  end

  def merge_mappings
    params[:metadata_builder][:field_mappings] = params[:metadata_builder][:field_mappings].to_s
  end

  def merge_xml
    params[:metadata_builder][:xml] = params[:metadata_builder][:xml].to_s
  end

  def build_xml
    @metadata_builder = MetadataBuilder.find(params[:id])
    @metadata_builder.build_xml_files(eval(params[:metadata_builder][:xml]))
  end

end
