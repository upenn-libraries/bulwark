class MetadataBuildersController < ApplicationController

  before_action :_set_metadata_builder, only: [:show, :edit, :update, :ingest, :set_source, :set_preserve, :clear_files]

  before_save :set_metadata_source_params

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
      @metadata_builder.metadata_source.each do |source|
        # set params?
      end
      redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/preview_xml", :flash => { :success => "Metadata mappings successfully updated.  See XML preview below."}
    else
      redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/preview_xml", :flash => { :error => @error_message }
    end
  end

  def ingest
    @message = @metadata_builder.transform_and_ingest(params[:to_ingest])
    redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/ingest", :flash => { @message.keys.first => @message.values.first }
  end

  def set_source
    @metadata_builder.set_source(params[:metadata_builder][:source].reject!(&:empty?))
    redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/preserve", :flash => { :success => "Metadata sources set successfully." }
  end

  def set_preserve
    @metadata_builder.set_preserve(params[:preserve_files])
    redirect_to "#{root_url}admin_repo/repo/#{@metadata_builder.repo.id}/preserve", :flash => { :success => "Preservation files designated successfully." }
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
      :metadata_source_attributes => [:view_type, :num_objects, :x_start, :y_start, :x_stop, :y_stop, :original_mappings, :root_element, :parent_element, :user_defined_mappings, :children => []])
  end

end
