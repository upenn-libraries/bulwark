class MetadataBuildersController < ApplicationController

  before_action :_set_metadata_builder, only: [:show, :edit, :update, :ingest, :set_source, :set_preserve, :clear_files, :refresh_metadata, :fetch_voyager, :generate_metadata, :generate_preview_xml]

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
        redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/#{_return_location}", :flash => { :error => errors_rendered }
      else
        redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/#{_return_location}", :flash => { :success => "Metadata Builder updated successfully."}
      end
    else
      redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/#{_return_location}", :flash => { :error => "Metadata Builder was not updated successfully."}
    end
  end

  def refresh_metadata
    @job = MetadataExtractionJob.perform_later(@metadata_builder, root_url, current_user.email)
    session[:metadata_extraction_job_id] = @job.job_id
    redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/generate_metadata", :flash => { :success => "Metadata being refreshed.  You will receive notification when it is complete."}
  end

  def generate_metadata
    @message = @metadata_builder.update(metadata_builder_params)
    redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/generate_metadata", :flash => { @message.keys.first => @message.values.first }
  end

  def custom_metadata_mapping
    @job_id = @job.job_id
  end

  def generate_preview_xml
    @job = GenerateXmlJob.perform_later(@metadata_builder, root_url, current_user.email)
    session[:generate_xml_job_id] = @job.job_id
    redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/preview_xml", :flash => { :success => "Preservation XML being generated.  You will receive notification when it is complete."}
  end

  def ingest
    if params[:to_ingest].present?
      @job = IngestJob.perform_later(@metadata_builder, params[:to_ingest], root_url, current_user.email)
      session[:ingest_job_id] = @job.job_id
      redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/ingest", :flash => { :success => "Object queued for processing.  You will receive notification when it is complete." }
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
    params.require(:metadata_builder).permit(:parent_repo,
      :metadata_source_attributes => [:id, :view_type, :num_objects, :x_start, :y_start, :x_stop, :y_stop, :original_mappings, :root_element, :parent_element, :user_defined_mappings, :children => []])
  end

  def _update_metadata_sources
    params[:metadata_builder][:metadata_source_attributes].each do |a|
      hash_params_strings = Hash[*Hash[*a.flatten(1)].values.flatten(0)]
      hash_params = Hash[hash_params_strings.map{|k,v| [k.to_sym, v]}]
      metadata_source = MetadataSource.find(hash_params[:id])
      metadata_source.update(hash_params)
      metadata_source.update_last_used_settings if (hash_params.keys & MetadataSource.settings_fields).present?
      metadata_source.errors.messages.each do |key, message|
        @metadata_builder.errors[:base] << message
      end
    end
  end

  def _return_location
    return_location = params[:metadata_builder][:metadata_source_attributes].any?{ |h| h.last.keys.any? { |i| ["user_defined_mappings", "root_element"].index i } } ? "generate_metadata" : "preserve"
  end

end
