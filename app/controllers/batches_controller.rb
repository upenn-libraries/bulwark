class BatchesController < ApplicationController
  before_action :set_batch, only: [:show, :process_batch]

  def new
  end

  def create
    @batch = Batch.new
  end

  def show
    'Batch show'
  end

  def process_batch
    @job = ProcessBatchJob.perform_later(@batch, root_url, current_user.email)
    initialize_job_activity('process_batch')
    redirect_to "#{root_url}admin_repo/batch/#{@batch.id}/process_batch", :flash =>  { :warning => t('colenda.batches.process_batch.success') }
  end

  def initialize_job_activity(process)
    current_user.job_activity[@job.job_id] = { :unique_identifier => @manifest.unique_identifier, :process => process, :started => DateTime.now }
    current_user.save
  end

  private
  def set_batch
    @batch = Batch.find(params[:id])
  end

  def batch_params
    params.require(:batch).permit(:queue_list, :email)
  end

end
