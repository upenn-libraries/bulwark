module Maintenance
  class DeleteSearches < ActiveJob::Base
    queue_as :maintenance

    # Deletes all the searches that are older than seven days. This job should
    # be scheduled to run regularly.
    def perform
      Search.where(created_at: Date.new..7.days.ago, user: nil)
            .find_in_batches(batch_size: 100) { |batch| batch.each(&:destroy) }
    end
  end
end
