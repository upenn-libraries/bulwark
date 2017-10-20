class Batch < ActiveRecord::Base

  validates :queue_list, presence: true
  validates :email, presence: true

  serialize :queue_list, Array

  around_create :check_things

  def check_things
    yield
  end

  def queue_list=(queue_list)
    queued = Array.wrap(queue_list).reject(&:blank?)
    self[:queue_list] = queued
    set_queued_status(queued)
  end

  def email=(email)
    self[:email] = email
  end

  def set_queued_status(queue_list)
    queue_list.each do |qid|
      repos_check = Repo.where(:unique_identifier => qid)
      raise 'Two repos with same unique identifier!' if repos_check.length > 1
      repo = repos_check.first
      repo.queued = 'fedora'
      repo.save!
    end
  end

  def load_all_queueable
    return Repo.where('queued' => 'ingest').pluck(:human_readable_name, :unique_identifier)
  end
end
