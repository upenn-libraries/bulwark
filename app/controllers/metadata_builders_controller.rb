class MetadataBuildersController < ApplicationController

  before_action :_set_metadata_builder, only: [:show, :edit, :update, :queue_for_ingest, :remove_from_queue, :set_source, :clear_files, :refresh_metadata, :generate_metadata, :generate_preview_xml, :file_checks]

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
      @metadata_builder.repo.update_last_action(action_description[:metadata_sources_updated])
      if @metadata_builder.errors.present?
        errors_rendered = Array[*@metadata_builder.errors.messages.values.flatten(1)].join(";  ").html_safe
        redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/#{_return_location}", :flash => { :error => errors_rendered }
      else
        redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/#{_return_location}", :flash => { :success => t('colenda.controllers.metadata_builders.update.success')}
      end
    else
      redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/#{_return_location}", :flash => { :error => t('colenda.controllers.metadata_builders.update.error')}
    end
  end

  def refresh_metadata
    @job = MetadataExtractionJob.perform_later(@metadata_builder, root_url, current_user.email)
    initialize_job_activity('metadata_extraction')
    redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/generate_metadata"
    @metadata_builder.repo.update_last_action(action_description[:metadata_extracted])
  end

  def generate_metadata
    @message = @metadata_builder.update(metadata_builder_params)
    @metadata_builder.repo.update_last_action(action_description[:metadata_mappings_generated])
    redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/generate_metadata", :flash => { @message.keys.first => @message.values.first }
  end

  def generate_preview_xml
    @job = GenerateXmlJob.perform_later(@metadata_builder, root_url, current_user.email)
    initialize_job_activity('generate_xml')
    @metadata_builder.repo.update_last_action(action_description[:preservation_xml_generated])
    redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/preview_xml"
  end

  def file_checks
    @job = FileChecksJob.perform_later(@metadata_builder, root_url, current_user.email)
    initialize_job_activity('file_checks')
    @metadata_builder.repo.update_last_action(action_description[:file_checks_run])
    redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/files_check", :flash =>  { :warning => t('colenda.controllers.metadata_builders.file_checks.success') }
  end

  def queue_for_ingest
    if params[:metadata_builder].present?
      key = @metadata_builder.update_queue_status(params[:metadata_builder])
      @metadata_builder.repo.update_last_action(action_description[key])
      redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/ingest"
    end
  end

  def remove_from_queue
    if params[:metadata_builder][:remove_from_ingest_queue].present?
      @metadata_builder.update_queue_status(params[:metadata_builder])
      @metadata_builder.repo.update_last_action(action_description[:removed_from_queue])
      redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/ingest"
    end
  end

  def set_source
    @metadata_builder.set_source(params[:metadata_builder][:source].reject!(&:empty?))
    @metadata_builder.repo.update_last_action(action_description[:metadata_sources_updated])
    redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/preserve", :flash => { :success => t('colenda.controllers.metadata_builders.set_source.success') }
  end

  def clear_files
    @metadata_builder.clear_unidentified_files
    redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/preserve", :flash => { :success => t('colenda.controllers.metadata_builders.clear_files.success') }
  end

  def initialize_job_activity(process)
    current_user.job_activity[@job.job_id] = { :unique_identifier => @metadata_builder.repo.unique_identifier, :process => process, :started => DateTime.now }
    current_user.save
  end

  private

  def action_description
    { :metadata_sources_updated => 'Metadata source information updated',
      :metadata_extracted => 'Metadata extraction from source(s) initialized',
      :metadata_mappings_generated => 'Metadata mappings set',
      :file_checks_run => 'File checks and derivative generation initialized',
      :preservation_xml_generated => 'Preservation XML generation initialized',
      :review_complete => 'Pre-Fedora review complete',
      :remove_from_queue => 'Removed from queue',
      :queued_for_ingest => 'Queued for ingest',
      :removed_from_queue => 'Removed from ingest queue',
      :published_preview => 'Object ingestion initialized' }
  end

  def _set_metadata_builder
    @metadata_builder = MetadataBuilder.find(params[:id])
  end

  def metadata_builder_params
    params.require(:metadata_builder).permit(:parent_repo,
                                             :metadata_source_attributes => [:id,
                                                                             :view_type,
                                                                             :num_objects,
                                                                             :x_start,
                                                                             :y_start,
                                                                             :x_stop,
                                                                             :y_stop,
                                                                             :original_mappings,
                                                                             :root_element,
                                                                             :parent_element,
                                                                             :user_defined_mappings,
                                                                             :file_field,
                                                                             :children => []])
  end

  def _update_metadata_sources
    params[:metadata_builder][:metadata_source_attributes].each do |a|
      hash_params_strings = Hash[*Hash[*a.flatten(1)].values.flatten(0)]
      hash_params = Hash[hash_params_strings.map{|k,v| [k.to_sym, v]}]
      metadata_source = MetadataSource.find(hash_params[:id])
      metadata_source.update(hash_params)
      metadata_source.update_last_used_settings if (hash_params.keys & MetadataSource.settings_fields).present?
      metadata_source.errors.messages.each do |error|
        @metadata_builder.errors[:base] << error.last
      end
    end
  end

  def _return_location
    return_location = params[:metadata_builder][:metadata_source_attributes].any?{ |h| h.last.keys.any? { |i| ['user_defined_mappings', 'root_element'].index i } } ? 'generate_metadata' : 'preserve'
  end

end
