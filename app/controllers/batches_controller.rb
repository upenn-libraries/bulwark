class BatchesController < ApplicationController
  before_action :set_batch, only: [:show]

  def new
  end

  def create
    @batch = Batch.new
  end

  def show
    'Batch show'
  end

  private
  def set_batch
    @batch = Batch.find(params[:id])
  end

  def batch_params
    params.require(:batch).permit(:queue_list, :email)
  end

end
