module Maintenance
  class DeleteSearches < ActiveJob::Base
    queue_as :maintenance

    # Deletes all searches. This job should be scheduled to run regularly.
    def perform
      Search.where(user: nil).delete_all # Using delete_all is faster because its a single SQL delete.
    end
  end
end
