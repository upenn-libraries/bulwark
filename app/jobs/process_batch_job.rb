class ProcessBatchJob < ActiveJobStatus::TrackableJob

  queue_as :process_batch

  after_perform :relay_message

  def perform(batch, root_url, user_email)
    @batch = batch
    @root_url = root_url
    @user_email = user_email
    @batch.process_batch
  end

  private

  def relay_message
    @batch.wrapup
  end

end
