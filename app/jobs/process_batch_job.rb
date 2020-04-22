class ProcessBatchJob < ActiveJobStatus::TrackableJob

  queue_as :process_batch

  def perform(batch, root_url, user_email)
    @batch = batch
    @root_url = root_url
    @user_email = user_email
    @batch.process_batch
  end

end
