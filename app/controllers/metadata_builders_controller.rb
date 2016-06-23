class MetadataBuildersController < ApplicationController

  before_action :_set_metadata_builder, only: [:show, :edit, :update, :ingest, :set_source, :set_preserve, :clear_files, :refresh_metadata, :generate_metadata, :generate_preview_xml]

  def show
  end

  def new
    @metadata_builder = MetadataBuilder.new
    @metadata_builder.metadata_source.build!
  end

  def edit
  end

  def update
    if @metadata_builder.update(metadata_builder_params)
      _update_metadata_sources if params[:metadata_builder][:metadata_source_attributes].present?
      if @metadata_builder.errors.present?
        errors_rendered = Array[*@metadata_builder.errors.messages.values.flatten(1)].join(";  ").html_safe
        redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/generate_metadata", :flash => { :error => errors_rendered }
      else
        redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/generate_metadata", :flash => { :success => "Metadata Builder updated successfully."}
      end
    else
      redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/generate_metadata", :flash => { :error => "Metadata Builder was not updated successfully."}
    end
  end

  def refresh_metadata
    @metadata_builder.refresh_metadata_from_source
    redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/generate_metadata", :flash => { :success => "Metadata refreshed.  See output below."}
  end

  def generate_metadata
    @message = @metadata_builder.update(metadata_builder_params)
    redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/generate_metadata", :flash => { @message.keys.first => @message.values.first }
  end

  def generate_preview_xml
    @metadata_builder.build_xml_files
    redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/preview_xml", :flash => { :success => "Preservation XML generated successfully.  See preview below."}
  end

  def ingest
    if params[:to_ingest].present?
      @message = @metadata_builder.transform_and_ingest(params[:to_ingest])
      redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/ingest", :flash => { @message.keys.first => @message.values.first }
    else
      redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/ingest", :flash => { :error => "Select at least one file to ingest."}
    end
  end

  def set_source
    @metadata_builder.set_source(params[:metadata_builder][:source].reject!(&:empty?))
    redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/preserve", :flash => { :success => "Metadata sources set successfully." }
  end

  def clear_files
    @metadata_builder.clear_unidentified_files
    redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/preserve", :flash => { :success => "Unidentified files have been removed from the repository." }
  end

  private

  def _set_metadata_builder
    @metadata_builder = MetadataBuilder.find(params[:id])
  end

  def metadata_builder_params
    params.require(:metadata_builder).permit(
      :metadata_source_attributes => [:id, :view_type, :num_objects, :x_start, :y_start, :x_stop, :y_stop, :original_mappings, :root_element, :parent_element, :user_defined_mappings, :children => []])
  end

  def _update_metadata_sources
    params[:metadata_builder][:metadata_source_attributes].each do |a|
      hash_params_strings = Hash[*Hash[*a.flatten(1)].values.flatten(0)]
      hash_params = Hash[hash_params_strings.map{|k,v| [k.to_sym, v]}]
      metadata_source = MetadataSource.find(hash_params[:id])
      metadata_source.update(hash_params)
      metadata_source.errors.messages.each do |key, message|
        @metadata_builder.errors[:base] << message
      end
    end
  end

end
