class Batch < ActiveRecord::Base

  validates :queue_list, presence: true
  validates :email, presence: true

  serialize :queue_list, Array

  around_create :queue_repos

  before_destroy :dequeue_repos

  def queue_repos
    yield
    set_queued_status(self.queue_list, {:action => 'add'})
    relay_message('create')
  end

  def dequeue_repos
    errors.add(:base, 'Batch in process to Fedora, cannot delete') if self.status == 'in_progress'
    return false if errors.present?
    set_queued_status(self.queue_list, {:action => 'remove'}) if errors.blank?
    relay_message('remove')
  end

  def queue_list=(queue_list)
    queued = Array.wrap(queue_list).reject(&:blank?)
    self[:queue_list] = queued
  end

  def email=(email)
    self[:email] = email
  end

  def set_queued_status(queue_list, options = {})
    queue_list.each do |qid|
      repos_check = Repo.where(:unique_identifier => qid)
      raise 'Two repos with same unique identifier!' if repos_check.length > 1
      repo = repos_check.first
      if options[:action] == 'add'
        repo.queued = 'fedora'
        repo.update_last_action('Queued for Fedora')
      elsif options [:action] == 'remove'
        repo.queued = 'ingest'
        repo.update_last_action('Pre-Fedora review complete')
      elsif options [:action] == 'processed'
        repo.queued = 'processed'
        repo.update_last_action('Ingested to Fedora')
      else
        return
      end
    end
  end

  def load_all_queueable
    return Repo.where('queued' => 'ingest').pluck(:human_readable_name, :unique_identifier)
  end

  def activate
    self.status = 'in_progress'
    self.save!
  end

  def wrapup
    self.status = 'complete'
    set_queued_status(self.queue_list, {:action => 'processed'})
    relay_message('processed')
  end

  private

  def relay_message(action)
    if action == 'create'
      MessengerClient.client.publish(I18n.t('rabbitmq.publish.messages.batch_created'))
      NotificationMailer.process_completed_email(I18n.t('colenda.mailers.notification.batch_created.subject'), BatchOps.config[:email], I18n.t('colenda.mailers.notification.batch_created.body', :uuid => self.id, :queue_list => self.queue_list)).deliver_now
    elsif action == 'remove'
      MessengerClient.client.publish(I18n.t('rabbitmq.publish.messages.batch_removed'))
      NotificationMailer.process_completed_email(I18n.t('colenda.mailers.notification.batch_removed.subject'), BatchOps.config[:email], I18n.t('colenda.mailers.notification.batch_removed.body', :uuid => self.id, :queue_list => self.queue_list)).deliver_now
    elsif action == 'processed'
      MessengerClient.client.publish(I18n.t('rabbitmq.publish.messages.batch_processed'))
      NotificationMailer.process_completed_email(I18n.t('colenda.mailers.notification.batch_processed.subject'), BatchOps.config[:email], I18n.t('colenda.mailers.notification.batch_processed.body', :uuid => self.id, :queue_list => self.queue_list)).deliver_now
    end
  end

end
